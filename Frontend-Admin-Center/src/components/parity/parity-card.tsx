import type { HTMLAttributes } from "react";

type ParityCardProps = HTMLAttributes<HTMLDivElement> & {
  kind?: "surface" | "foundation" | "overlay";
  padded?: boolean;
};

export function ParityCard({
  kind = "surface",
  padded = true,
  className = "",
  ...props
}: ParityCardProps) {
  const classes = [
    "parity-card",
    `parity-card--${kind}`,
    padded ? "parity-card--padded" : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return <div className={classes} {...props} />;
}
