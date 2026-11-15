import Image from "next/image";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import type { Order } from "@/lib/api/types";

/** What the customer told the workshop about their clothes when booking: the note and the photos they added. */
export function hasCareNote(order: Pick<Order, "careNote" | "carePhotoUrls">): boolean {
  return Boolean(order.careNote?.trim()) || order.carePhotoUrls.length > 0;
}

/**
 * Shown only when the customer left a note or photos. Photos are full size and open in a new tab, like report photos.
 * Separate from the pickup instructions, which are for the pickup partner.
 */
export function CareNoteCard({ order }: { order: Order }) {
  if (!hasCareNote(order)) return null;
  const note = order.careNote?.trim();
  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">Care note</CardTitle>
        <CardDescription>From the customer, for the workshop. The pickup instructions are separate.</CardDescription>
      </CardHeader>
      <CardContent className="flex flex-col gap-4">
        {note ? <p className="whitespace-pre-line text-sm">{note}</p> : null}
        {order.carePhotoUrls.length > 0 ? (
          <div className="grid gap-3 sm:grid-cols-2">
            {order.carePhotoUrls.map((url, index) => (
              <a key={url} href={url} target="_blank" rel="noreferrer" className="rounded-md border p-2">
                <Image
                  unoptimized
                  src={url}
                  alt={`Customer photo ${index + 1} of ${order.carePhotoUrls.length}; open full image`}
                  width={1200}
                  height={1200}
                  className="max-h-[28rem] w-full object-contain"
                />
              </a>
            ))}
          </div>
        ) : null}
      </CardContent>
    </Card>
  );
}
