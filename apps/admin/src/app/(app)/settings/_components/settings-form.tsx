"use client";

import { zodResolver } from "@hookform/resolvers/zod";
import { useQueryClient } from "@tanstack/react-query";
import { useEffect, useMemo } from "react";
import { useUnsavedChanges } from "@/hooks/use-unsaved-changes";
import { useAuth } from "@/lib/auth/auth-provider";
import { useForm, type UseFormRegister } from "react-hook-form";
import { z } from "zod";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { InputGroup, InputGroupAddon, InputGroupInput, InputGroupText } from "@/components/ui/input-group";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { components } from "@/lib/api/schema";
import type { BusinessSettings } from "@/lib/api/types";
import { paiseToInput, toPaise } from "@/lib/format";

type SettingsPatch = components["schemas"]["UpdateSettingsDto"];

// Upper bounds only guard against typos that the database would reject.
const MAX_PAISE = 10_000_000; // ₹1,00,000
const MAX_WHOLE = 10_000;

const MONEY_MESSAGE = "Enter an amount in rupees, like 40 or 49.50.";
const money = z
  .string()
  .trim()
  .refine((v) => toPaise(v) !== null, MONEY_MESSAGE)
  .refine((v) => (toPaise(v) ?? 0) <= MAX_PAISE, "That amount is too large.");
const optionalMoney = z
  .string()
  .trim()
  .refine((v) => v === "" || toPaise(v) !== null, MONEY_MESSAGE)
  .refine((v) => (toPaise(v) ?? 0) <= MAX_PAISE, "That amount is too large.");
const optionalNumber = (pattern: RegExp, min: number, max: number, message: string) =>
  z
    .string()
    .trim()
    .refine((v) => v === "" || (pattern.test(v) && Number(v) >= min && Number(v) <= max), message);

const PINCODE = /^[1-9]\d{5}$/;
/** "500033, 500034" → sorted unique list, or null when any entry is not a PIN code. */
function parsePincodes(v: string): string[] | null {
  const codes = v.split(/[\s,]+/).filter(Boolean);
  return codes.every((c) => PINCODE.test(c)) ? [...new Set(codes)].sort() : null;
}

const RADIUS_KEYS = ["serviceCenterLatitude", "serviceCenterLongitude", "serviceRadiusKm"] as const;

const whole = (min: number) =>
  z
    .string()
    .trim()
    .regex(/^\d+$/, "Enter a whole number.")
    .refine((v) => Number(v) >= min, `Enter ${min} or more.`)
    .refine((v) => Number(v) <= MAX_WHOLE, "That number is too large.");

const schema = z.object({
  adjustmentExpiryHours: whole(1).refine((v) => Number(v) <= 168, "Enter 1 to 168 hours."),
  issueFirstResponseHours: optionalNumber(/^\d+$/, 1, 168, "Enter 1 to 168 hours, or leave empty."),
  minOrderPaise: money,
  deliveryFeePaise: money,
  freeDeliveryAbovePaise: optionalMoney,
  bookingCutoffMinutes: whole(0),
  maxAdvanceDays: whole(1),
  minTurnaroundHours: whole(1),
  pickupCapacityPerSlot: optionalNumber(/^\d+$/, 1, 1000, "Enter 1 to 1000, or leave empty for no limit."),
  dispatchLeadMinutes: whole(0),
  dispatchBatchSize: whole(1),
  offerTimeoutSeconds: whole(5),
  dispatchRetryMinutes: whole(1),
  driverMaxActiveLegs: whole(1),
  driverLocationMaxAgeMinutes: whole(1),
  supportPhone: z
    .string()
    .trim()
    .max(20, "Keep it under 20 characters.")
    .refine((v) => v === "" || /^\+?\d{8,15}$/.test(v.replace(/[\s-]/g, "")), "Enter a phone number, like +91 98765 43210."),
  supportEmail: z
    .string()
    .trim()
    .refine((v) => v === "" || z.email().safeParse(v).success, "Enter a valid email address."),
  serviceCenterLatitude: optionalNumber(/^-?\d{1,2}(\.\d+)?$/, -90, 90, "Enter a latitude, like 17.4126."),
  serviceCenterLongitude: optionalNumber(/^-?\d{1,3}(\.\d+)?$/, -180, 180, "Enter a longitude, like 78.4482."),
  serviceRadiusKm: optionalNumber(/^\d{1,3}(\.\d)?$/, 0.5, 100, "Enter 0.5 to 100 km, with at most one decimal."),
  servicePincodes: z
    .string()
    .trim()
    .refine((v) => parsePincodes(v) !== null, "Separate 6-digit PIN codes with commas, like 500033, 500034."),
}).superRefine((v, ctx) => {
  const filled = RADIUS_KEYS.filter((key) => v[key].trim() !== "");
  if (filled.length === 0 || filled.length === RADIUS_KEYS.length) return;
  for (const key of RADIUS_KEYS) {
    if (v[key].trim() === "") {
      ctx.addIssue({ code: "custom", path: [key], message: "Fill in the hub location and radius together, or leave all three empty." });
    }
  }
});

type Values = z.input<typeof schema>;
type Key = keyof Values;

const WHOLE_KEYS = [
  "adjustmentExpiryHours",
  "bookingCutoffMinutes",
  "maxAdvanceDays",
  "minTurnaroundHours",
  "dispatchLeadMinutes",
  "dispatchBatchSize",
  "offerTimeoutSeconds",
  "dispatchRetryMinutes",
  "driverMaxActiveLegs",
  "driverLocationMaxAgeMinutes",
] as const satisfies readonly Key[];

function toValues(s: BusinessSettings): Values {
  const values: Values = {
    adjustmentExpiryHours: String(s.adjustmentExpiryHours),
    issueFirstResponseHours: s.issueFirstResponseHours?.toString() ?? "",
    minOrderPaise: paiseToInput(s.minOrderPaise),
    deliveryFeePaise: paiseToInput(s.deliveryFeePaise),
    freeDeliveryAbovePaise: paiseToInput(s.freeDeliveryAbovePaise),
    pickupCapacityPerSlot: s.pickupCapacityPerSlot?.toString() ?? "",
    bookingCutoffMinutes: "",
    maxAdvanceDays: "",
    minTurnaroundHours: "",
    dispatchLeadMinutes: "",
    dispatchBatchSize: "",
    offerTimeoutSeconds: "",
    dispatchRetryMinutes: "",
    driverMaxActiveLegs: "",
    driverLocationMaxAgeMinutes: "",
    supportPhone: s.supportPhone ?? "",
    supportEmail: s.supportEmail ?? "",
    serviceCenterLatitude: s.serviceCenterLatitude?.toString() ?? "",
    serviceCenterLongitude: s.serviceCenterLongitude?.toString() ?? "",
    serviceRadiusKm: s.serviceRadiusKm?.toString() ?? "",
    servicePincodes: s.servicePincodes.join(", "),
  };
  for (const key of WHOLE_KEYS) values[key] = String(s[key]);
  return values;
}

/** Only what differs from the saved settings, converted to API units. */
function toPatch(v: Values, s: BusinessSettings): SettingsPatch {
  const patch: SettingsPatch = {};
  for (const key of ["minOrderPaise", "deliveryFeePaise"] as const) {
    const paise = toPaise(v[key]);
    if (paise !== null && paise !== s[key]) patch[key] = paise;
  }
  const replyHours = v.issueFirstResponseHours === "" ? null : Number(v.issueFirstResponseHours);
  if (replyHours !== s.issueFirstResponseHours) patch.issueFirstResponseHours = replyHours;
  const freeAbove = v.freeDeliveryAbovePaise === "" ? null : toPaise(v.freeDeliveryAbovePaise);
  if (freeAbove !== s.freeDeliveryAbovePaise) patch.freeDeliveryAbovePaise = freeAbove;
  for (const key of WHOLE_KEYS) {
    const n = Number(v[key]);
    if (n !== s[key]) patch[key] = n;
  }
  const capacity = v.pickupCapacityPerSlot.trim() === "" ? null : Number(v.pickupCapacityPerSlot);
  if (capacity !== s.pickupCapacityPerSlot) patch.pickupCapacityPerSlot = capacity;
  if (v.supportPhone !== (s.supportPhone ?? "")) patch.supportPhone = v.supportPhone;
  if (v.supportEmail !== (s.supportEmail ?? "")) patch.supportEmail = v.supportEmail;
  for (const key of RADIUS_KEYS) {
    const n = v[key].trim() === "" ? null : Number(v[key]);
    if (n !== s[key]) patch[key] = n;
  }
  const pincodes = parsePincodes(v.servicePincodes) ?? [];
  if (pincodes.join() !== s.servicePincodes.join()) patch.servicePincodes = pincodes;
  return patch;
}

interface FieldDef {
  name: Key;
  label: string;
  hint: string;
  prefix?: string;
  suffix?: string;
  inputMode: "numeric" | "decimal" | "tel" | "email" | "text";
  placeholder?: string;
}

const SECTIONS: { title: string; description: string; fields: FieldDef[] }[] = [
  { title: "Price approvals and support", description: "Only promise response times the team can staff.", fields: [
    { name: "adjustmentExpiryHours", label: "Price approval expires after", suffix: "hours", inputMode: "numeric", hint: "Default 12 hours. Unanswered requests expire and the previously accepted bill stays in place. Allowed: 1–168 hours." },
    { name: "issueFirstResponseHours", label: "Public first response target", suffix: "hours", inputMode: "numeric", placeholder: "Off", hint: "Leave empty until support staffing is confirmed. When set, new reports show this deadline to customers. Existing reports keep their original target." },
  ] },
  {
    title: "Pricing",
    description: "What customers pay on top of their items. Existing orders keep the prices they were booked with.",
    fields: [
      {
        name: "minOrderPaise",
        label: "Minimum order",
        prefix: "₹",
        inputMode: "decimal",
        hint: "Customers cannot place an order whose items add up to less than this. Use 0 for no minimum.",
      },
      {
        name: "deliveryFeePaise",
        label: "Travel charge",
        prefix: "₹",
        inputMode: "decimal",
        hint: "A flat charge added to orders under the free-travel amount. Use 0 to never charge it. Existing orders keep the charge they were booked with.",
      },
      {
        name: "freeDeliveryAbovePaise",
        label: "Free travel from (items total before coupons)",
        prefix: "₹",
        inputMode: "decimal",
        placeholder: "Never free",
        hint: "Orders whose items add up to this much or more, counted before any coupon, pay no travel charge. A coupon never brings a free order back under it. Leave empty to always charge it.",
      },
    ],
  },
  {
    title: "Scheduling",
    description: "Which pickup and delivery slots customers can choose.",
    fields: [
      {
        name: "bookingCutoffMinutes",
        label: "Booking cutoff",
        suffix: "min before slot ends",
        inputMode: "numeric",
        hint: "A pickup slot stays open for booking until this many minutes before it ends.",
      },
      {
        name: "maxAdvanceDays",
        label: "Book ahead up to",
        suffix: "days",
        inputMode: "numeric",
        hint: "How many days ahead customers can schedule a pickup or delivery.",
      },
      {
        name: "minTurnaroundHours",
        label: "Time between pickup and delivery",
        suffix: "hours",
        inputMode: "numeric",
        hint: "The earliest delivery slot starts at least this many hours after the pickup slot starts.",
      },
      {
        name: "pickupCapacityPerSlot",
        label: "Pickups per time window",
        suffix: "pickups",
        inputMode: "numeric",
        placeholder: "No limit",
        hint: "How many orders still waiting for pickup (new, or with a partner assigned) one window can hold. A full window shows as Full to customers. Staff phone orders can still book into it with a reason. Leave empty for no limit.",
      },
    ],
  },
  {
    title: "Service area",
    description:
      "Where customers can book pickups. Customers outside it are told IronDost isn't in their area yet, and can ask to be told when we arrive (see Outside the area). Staff phone orders need a map pin or a served PIN code, and an address outside the area needs a typed reason. Test the edge with Check an address below.",
    fields: [
      {
        name: "serviceCenterLatitude",
        label: "Hub latitude",
        inputMode: "decimal",
        placeholder: "17.4126",
        hint: "Your hub's location, used with the radius. In Google Maps, right-click the hub to copy its coordinates.",
      },
      {
        name: "serviceCenterLongitude",
        label: "Hub longitude",
        inputMode: "decimal",
        placeholder: "78.4482",
        hint: "Leave the hub and radius empty for no distance limit.",
      },
      {
        name: "serviceRadiusKm",
        label: "Serve within",
        suffix: "km of the hub",
        inputMode: "decimal",
        placeholder: "No limit",
        hint: "Addresses farther than this from the hub can't book a pickup.",
      },
      {
        name: "servicePincodes",
        label: "Served PIN codes",
        inputMode: "text",
        placeholder: "Every PIN code",
        hint: "Only these PIN codes can book. Separate them with commas. Leave empty to allow every PIN code.",
      },
    ],
  },
  {
    title: "Dispatch",
    description: "How pickups and deliveries are offered to delivery partners.",
    fields: [
      {
        name: "dispatchLeadMinutes",
        label: "Start looking for a partner",
        suffix: "min before slot",
        inputMode: "numeric",
        hint: "Partners start getting the offer this many minutes before the pickup or delivery slot begins.",
      },
      {
        name: "dispatchBatchSize",
        label: "Partners offered per round",
        suffix: "partners",
        inputMode: "numeric",
        hint: "This many of the nearest available partners get each offer at once. The first to accept gets the task.",
      },
      {
        name: "offerTimeoutSeconds",
        label: "Time to accept",
        suffix: "seconds",
        inputMode: "numeric",
        hint: "How long partners have to accept before the offer moves on. At least 5 seconds.",
      },
      {
        name: "dispatchRetryMinutes",
        label: "Retry every",
        suffix: "min",
        inputMode: "numeric",
        hint: "When no partner is available, look again after this long, until the slot ends.",
      },
      {
        name: "driverMaxActiveLegs",
        label: "Max active tasks per partner",
        suffix: "tasks",
        inputMode: "numeric",
        hint: "Partners already holding this many pickups and deliveries get no new offers.",
      },
      {
        name: "driverLocationMaxAgeMinutes",
        label: "Ignore partners whose location is older than",
        suffix: "min",
        inputMode: "numeric",
        hint: "Online partners whose app has not sent a location for this long are not offered tasks.",
      },
    ],
  },
  {
    title: "Support contact",
    description: "How customers reach IronDost for help.",
    fields: [
      {
        name: "supportPhone",
        label: "Support phone",
        inputMode: "tel",
        placeholder: "+91 98765 43210",
        hint: "The number customers call for help with an order.",
      },
      {
        name: "supportEmail",
        label: "Support email",
        inputMode: "email",
        placeholder: "help@example.com",
        hint: "Where customers can write to for help.",
      },
    ],
  },
];

export function SettingsForm({ settings, canEdit }: { settings: BusinessSettings; canEdit: boolean }) {
  const queryClient = useQueryClient();
  const { user } = useAuth();
  const draftKey = `irondost.settings.draft.${user?.id}`;
  const values = useMemo(() => toValues(settings), [settings]);
  const form = useForm<Values, unknown, z.output<typeof schema>>({
    resolver: zodResolver(schema),
    defaultValues: values,
    // Picks up fresh server values without discarding fields being edited.
    values,
    resetOptions: { keepDirtyValues: true },
    mode: "onTouched",
  });
  const { errors, isDirty } = form.formState;
  useUnsavedChanges(canEdit && isDirty);
  useEffect(() => {
    if (!canEdit) return;
    let active = true;
    void Promise.resolve().then(() => {
      if (!active) return;
      try {
        const changes = JSON.parse(sessionStorage.getItem(draftKey) ?? "{}");
        const parsed = schema.safeParse({ ...form.getValues(), ...changes });
        if (parsed.success && Object.keys(changes).length) form.reset(parsed.data, { keepDefaultValues: true, keepDirtyValues: false });
      } catch { /* Storage can be unavailable; the leave guard still works. */ }
    });
    // eslint-disable-next-line react-hooks/incompatible-library -- subscription is isolated from rendered values
    const watch = form.watch((current) => {
      const changed = Object.fromEntries(Object.entries(current).filter(([key]) => form.getFieldState(key as Key).isDirty));
      try { if (Object.keys(changed).length) sessionStorage.setItem(draftKey, JSON.stringify(changed)); else sessionStorage.removeItem(draftKey); } catch {}
    });
    return () => { active = false; watch.unsubscribe(); };
  }, [canEdit, draftKey, form]);

  const save = useApiMutation((body: SettingsPatch) => unwrap(api.PATCH("/v1/admin/settings", { body })), {
    success: "Saved",
    onSuccess: (data) => {
      queryClient.setQueryData(["settings"], data);
      form.reset(toValues(data), { keepDirtyValues: false, keepDirty: false });
      try { sessionStorage.removeItem(draftKey); } catch {}
    },
  });

  const onSubmit = form.handleSubmit((v) => {
    const patch = toPatch(v, settings);
    if (Object.keys(patch).length === 0) {
      // Only whitespace changed.
      form.reset(values, { keepDirtyValues: false, keepDirty: false });
      return;
    }
    save.mutate(patch);
  });

  return (
    <form onSubmit={onSubmit} noValidate className="flex flex-col gap-6">
      <fieldset disabled={!canEdit || save.isPending} className="grid min-w-0 max-w-4xl gap-6">
        <legend className="sr-only">Business settings</legend>
        {SECTIONS.map((section) => (
          <Card key={section.title}>
            <CardHeader>
              <CardTitle className="text-base">{section.title}</CardTitle>
              <CardDescription>{section.description}</CardDescription>
            </CardHeader>
            <CardContent className="grid gap-x-6 gap-y-5 sm:grid-cols-2">
              {section.fields.map((field) => (
                <SettingField key={field.name} def={field} register={form.register} error={errors[field.name]?.message} />
              ))}
            </CardContent>
          </Card>
        ))}
      </fieldset>

      {canEdit ? (
        <div className="sticky bottom-0 z-10 -mx-4 -mb-5 flex flex-wrap items-center justify-end gap-3 border-t bg-background/95 px-4 py-3 backdrop-blur md:-mx-6 md:px-6">
          <p className="mr-auto text-sm text-muted-foreground" aria-live="polite">
            {isDirty ? "You have unsaved changes. This tab keeps a draft." : "No unsaved changes."}
          </p>
          <Button type="button" variant="ghost" disabled={!isDirty || save.isPending} onClick={() => { if (window.confirm("Discard your unsaved settings?")) { form.reset(values, { keepDirtyValues: false, keepDirty: false }); try { sessionStorage.removeItem(draftKey); } catch {} } }}>
            Discard changes
          </Button>
          <Button type="submit" disabled={!isDirty || save.isPending}>
            {save.isPending ? "Saving…" : "Save changes"}
          </Button>
        </div>
      ) : null}
    </form>
  );
}

function SettingField({
  def,
  register,
  error,
}: {
  def: FieldDef;
  register: UseFormRegister<Values>;
  error?: string;
}) {
  const id = `setting-${def.name}`;
  return (
    <div className="grid content-start gap-1.5">
      <Label htmlFor={id}>{def.label}</Label>
      <InputGroup>
        {def.prefix ? (
          <InputGroupAddon>
            <InputGroupText>{def.prefix}</InputGroupText>
          </InputGroupAddon>
        ) : null}
        <InputGroupInput
          id={id}
          type={def.inputMode === "email" ? "email" : def.inputMode === "tel" ? "tel" : "text"}
          inputMode={def.inputMode}
          placeholder={def.placeholder}
          autoComplete="off"
          className={def.prefix || def.suffix ? "tabular" : undefined}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? `${id}-error ${id}-hint` : `${id}-hint`}
          {...register(def.name)}
        />
        {def.suffix ? (
          <InputGroupAddon align="inline-end">
            <InputGroupText>{def.suffix}</InputGroupText>
          </InputGroupAddon>
        ) : null}
      </InputGroup>
      {error ? (
        <p id={`${id}-error`} className="text-xs text-destructive">
          {error}
        </p>
      ) : null}
      <p id={`${id}-hint`} className="text-xs text-muted-foreground">
        {def.hint}
      </p>
    </div>
  );
}
