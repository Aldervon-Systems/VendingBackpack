import type { ButtonHTMLAttributes } from "react";

type ParityButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  tone?: "accent" | "dark" | "ghost";
  fullWidth?: boolean;
};

export function ParityButton({
  tone = "accent",
  fullWidth = false,
  className = "",
  type = "button",
  ...props
}: ParityButtonProps) {
  const classes = [
    "parity-button",
    `parity-button--${tone}`,
    fullWidth ? "parity-button--full" : "",
    className,
  ]
    .filter(Boolean)
    .join(" ");

  return <button type={type} className={classes} {...props} />;
}
