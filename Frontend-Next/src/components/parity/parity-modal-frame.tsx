import type { ReactNode } from "react";
import { X } from "lucide-react";

type ParityModalFrameProps = {
  title: string;
  subtitle?: string;
  onClose?: () => void;
  children: ReactNode;
  className?: string;
};

export function ParityModalFrame({ title, subtitle, onClose, children, className = "" }: ParityModalFrameProps) {
  return (
    <div className={`parity-modal ${className}`.trim()}>
      <div className="parity-modal__header">
        <div>
          <div className="parity-modal__title">{title}</div>
          {subtitle ? <div className="parity-modal__subtitle">{subtitle}</div> : null}
        </div>
        {onClose ? (
          <button className="parity-modal__close" type="button" onClick={onClose} aria-label="Close dialog">
            <X size={22} />
          </button>
        ) : null}
      </div>
      <div className="parity-modal__body">{children}</div>
    </div>
  );
}
