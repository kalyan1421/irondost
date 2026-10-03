import Image from "next/image";

/** The IronDost logo. [reverse] is for dark backgrounds. SVGs are served as they are, so they stay sharp at any size. */
export function BrandLogo({ reverse = false, height = 40 }: { reverse?: boolean; height?: number }) {
  // The logo drawing is 2400 x 585.
  const width = Math.round((height * 2400) / 585);
  return (
    <Image
      src={reverse ? "/brand/irondost-logo-reverse.svg" : "/brand/irondost-logo.svg"}
      alt="IronDost"
      width={width}
      height={height}
      unoptimized
      priority
    />
  );
}
