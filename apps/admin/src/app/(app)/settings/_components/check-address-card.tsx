"use client";

import { useMutation } from "@tanstack/react-query";
import { CircleCheck, Search, TriangleAlert } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, errorMessage, unwrap } from "@/lib/api/client";
import type { AddressCheck, BusinessSettings } from "@/lib/api/types";
import { cn } from "@/lib/utils";

const PINCODE = /^[1-9]\d{5}$/;
/** "17.4126, 78.4482": the pair Google Maps copies when you right-click a place. */
const PAIR = /^\s*(-?\d+(?:\.\d+)?)\s*[,\s]\s*(-?\d+(?:\.\d+)?)\s*$/;

type Body = { latitude?: number; longitude?: number; pincode?: string };
type Problems = Partial<Record<"latitude" | "longitude" | "pincode" | "form", string>>;

function validate(latitude: string, longitude: string, pincode: string): { body: Body } | { problems: Problems } {
  const problems: Problems = {};
  const lat = latitude.trim();
  const lng = longitude.trim();
  const pin = pincode.trim();
  const body: Body = {};
  if (lat !== "" || lng !== "") {
    const la = Number(lat);
    const lo = Number(lng);
    if (lat === "" || !Number.isFinite(la) || la < -90 || la > 90) problems.latitude = "Enter a latitude, like 17.4126.";
    if (lng === "" || !Number.isFinite(lo) || lo < -180 || lo > 180) problems.longitude = "Enter a longitude, like 78.4482.";
    if (!problems.latitude && !problems.longitude) {
      body.latitude = la;
      body.longitude = lo;
    }
  }
  if (pin !== "") {
    if (PINCODE.test(pin)) body.pincode = pin;
    else problems.pincode = "Enter a 6-digit PIN code.";
  }
  if (lat === "" && lng === "" && pin === "") problems.form = "Type a map position, a PIN code, or both.";
  return Object.keys(problems).length ? { problems } : { body };
}

/** What the saved settings are, in one line, so the answer below is read against the right rules. */
function describeSettings(s: BusinessSettings): string {
  const radius =
    s.serviceCenterLatitude !== null && s.serviceRadiusKm !== null ? `within ${s.serviceRadiusKm} km of the centre` : "no distance limit";
  const pins = s.servicePincodes.length > 0 ? `${s.servicePincodes.length} served PIN ${s.servicePincodes.length === 1 ? "code" : "codes"}` : "every PIN code";
  return `Saved settings: ${radius}, ${pins}.`;
}

interface Verdict {
  tone: "ok" | "bad" | "note";
  title: string;
  detail: string;
}

/** The answer in words, with the distance read against the radius and what could not be checked said plainly. */
export function describeResult(r: AddressCheck, asked: Body, s: BusinessSettings): Verdict {
  const radius = s.serviceRadiusKm;
  const distance = r.distanceKm !== null ? `${r.distanceKm} km from the centre` : null;
  if (!r.served) {
    if (r.reason === "OUTSIDE_RADIUS") {
      return {
        tone: "bad",
        title: "Not served: too far",
        detail: `${distance ?? "Beyond the radius"}${radius !== null ? `, past the ${radius} km limit` : ""}.`,
      };
    }
    return {
      tone: "bad",
      title: "Not served: PIN code not on the list",
      detail: `${asked.pincode ? `PIN code ${asked.pincode} is not one of the served PIN codes` : "This PIN code is not served"}${distance ? `. The place itself is ${distance}` : ""}.`,
    };
  }
  if (!r.verified) {
    return {
      tone: "note",
      title: "Nothing to check against",
      detail: "No limit applies to what you typed, so it counts as served. A phone order still needs a map pin or a PIN code on the served list.",
    };
  }
  if (asked.latitude !== undefined) {
    return { tone: "ok", title: "Served", detail: `${distance ?? "Inside the area"}${radius !== null && r.distanceKm !== null ? `, inside the ${radius} km limit` : ""}.` };
  }
  return {
    tone: "ok",
    title: "Served by PIN code",
    detail: `This PIN code is on the served list.${radius !== null ? " Add a map position to check the distance as well." : ""}`,
  };
}

/**
 * "Check an address": test the edge of the service area before customers meet it. Type a map position (or paste the pair Google Maps
 * copies), a PIN code, or both. It asks the server, so it uses the settings as last saved, never unsaved edits in the form above.
 */
export function CheckAddressCard({ settings }: { settings: BusinessSettings }) {
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [pincode, setPincode] = useState("");
  const [problems, setProblems] = useState<Problems>({});
  const [asked, setAsked] = useState<Body>({});

  const check = useMutation({
    mutationFn: (body: Body): Promise<AddressCheck> => unwrap(api.POST("/v1/admin/settings/check-address", { body })),
  });

  function edited() {
    setProblems({});
    if (check.data || check.error) check.reset();
  }

  /** Pasting "17.4126, 78.4482" (what Google Maps copies) into the latitude box fills both boxes. */
  function onPasteLocation(e: React.ClipboardEvent<HTMLInputElement>) {
    const pair = PAIR.exec(e.clipboardData.getData("text"));
    if (!pair) return;
    e.preventDefault();
    edited();
    setLatitude(pair[1]);
    setLongitude(pair[2]);
  }

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const result = validate(latitude, longitude, pincode);
    if ("problems" in result) {
      setProblems(result.problems);
      return;
    }
    setProblems({});
    setAsked(result.body);
    check.mutate(result.body);
  }

  const verdict = check.data ? describeResult(check.data, asked, settings) : null;

  return (
    <Card className="max-w-4xl">
      <form onSubmit={submit} noValidate>
        <CardHeader>
          <CardTitle className="text-base">Check an address</CardTitle>
          <CardDescription>
            See whether a place is served, and how far it is from the centre, before customers find the edge. It uses the settings as last saved: save any changes above first.
          </CardDescription>
        </CardHeader>
        <CardContent className="mt-4 grid gap-x-6 gap-y-5 sm:grid-cols-3">
          <div className="grid content-start gap-1.5">
            <Label htmlFor="check-latitude">Latitude</Label>
            <Input
              id="check-latitude"
              inputMode="decimal"
              autoComplete="off"
              placeholder="17.4126"
              className="tabular"
              value={latitude}
              aria-invalid={problems.latitude ? true : undefined}
              aria-describedby="check-latitude-hint"
              onPaste={onPasteLocation}
              onChange={(e) => {
                edited();
                setLatitude(e.target.value);
              }}
            />
            {problems.latitude ? <p className="text-xs text-destructive">{problems.latitude}</p> : null}
            <p id="check-latitude-hint" className="text-xs text-muted-foreground">
              You can paste both numbers here, as Google Maps copies them.
            </p>
          </div>
          <div className="grid content-start gap-1.5">
            <Label htmlFor="check-longitude">Longitude</Label>
            <Input
              id="check-longitude"
              inputMode="decimal"
              autoComplete="off"
              placeholder="78.4482"
              className="tabular"
              value={longitude}
              aria-invalid={problems.longitude ? true : undefined}
              onChange={(e) => {
                edited();
                setLongitude(e.target.value);
              }}
            />
            {problems.longitude ? <p className="text-xs text-destructive">{problems.longitude}</p> : null}
          </div>
          <div className="grid content-start gap-1.5">
            <Label htmlFor="check-pincode">PIN code</Label>
            <Input
              id="check-pincode"
              inputMode="numeric"
              autoComplete="off"
              placeholder="500034"
              className="tabular"
              maxLength={6}
              value={pincode}
              aria-invalid={problems.pincode ? true : undefined}
              onChange={(e) => {
                edited();
                setPincode(e.target.value.replace(/\D/g, "").slice(0, 6));
              }}
            />
            {problems.pincode ? <p className="text-xs text-destructive">{problems.pincode}</p> : null}
          </div>
        </CardContent>
        <CardFooter className="mt-5 flex-col items-stretch gap-3">
          <div className="flex flex-wrap items-center gap-3">
            <Button type="submit" disabled={check.isPending}>
              <Search /> {check.isPending ? "Checking…" : "Check address"}
            </Button>
            <p className="text-xs text-muted-foreground">{describeSettings(settings)}</p>
          </div>
          {problems.form ? (
            <p role="alert" className="text-sm text-destructive">
              {problems.form}
            </p>
          ) : null}
          <div aria-live="polite">
            {check.isError ? (
              <p role="alert" className="text-sm text-destructive">
                {errorMessage(check.error)}
              </p>
            ) : verdict ? (
              <div
                role="status"
                className={cn(
                  "flex items-start gap-2 rounded-lg border p-3 text-sm",
                  verdict.tone === "ok" && "border-success/40 bg-success/5",
                  verdict.tone === "bad" && "border-warning/50 bg-warning/5",
                  verdict.tone === "note" && "bg-muted/40",
                )}
              >
                {verdict.tone === "ok" ? <CircleCheck className="mt-0.5 size-4 shrink-0 text-success" /> : <TriangleAlert className="mt-0.5 size-4 shrink-0" />}
                <div className="grid gap-0.5">
                  <p className="font-medium">{verdict.title}</p>
                  <p className="text-muted-foreground">{verdict.detail}</p>
                </div>
              </div>
            ) : null}
          </div>
        </CardFooter>
      </form>
    </Card>
  );
}
