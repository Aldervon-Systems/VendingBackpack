import type { MouseEvent, ReactNode } from "react";

type ParityOverlayProps = {
  children: ReactNode;
  onBackdropClick?: () => void;
  align?: "center" | "sheet";
};

export function ParityOverlay({ children, onBackdropClick, align = "center" }: ParityOverlayProps) {
  function handleBackdropClick(event: MouseEvent<HTMLDivElement>) {
    if (event.target === event.currentTarget) {
      onBackdropClick?.();
    }
  }

  return (
    <div className={`parity-overlay parity-overlay--${align}`} onClick={handleBackdropClick}>
      {children}
    </div>
  );
}
