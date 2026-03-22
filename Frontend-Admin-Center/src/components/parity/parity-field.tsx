"use client";

import type { InputHTMLAttributes, ReactNode, SelectHTMLAttributes, TextareaHTMLAttributes } from "react";

type SelectOption = {
  label: string;
  value: string;
};

type BaseProps = {
  id: string;
  label: string;
  suffix?: ReactNode;
  className?: string;
};

type InputProps = BaseProps &
  InputHTMLAttributes<HTMLInputElement> & {
    as?: "input";
    options?: never;
  };

type SelectProps = BaseProps &
  Omit<SelectHTMLAttributes<HTMLSelectElement>, "onChange"> & {
    as: "select";
    options: SelectOption[];
    onChange?: (value: string) => void;
  };

type TextareaProps = BaseProps &
  TextareaHTMLAttributes<HTMLTextAreaElement> & {
    as: "textarea";
    options?: never;
  };

type ParityFieldProps = InputProps | SelectProps | TextareaProps;

export function ParityField(props: ParityFieldProps) {
  const { id, label, suffix, className = "" } = props;

  return (
    <label className={`parity-field ${className}`.trim()} htmlFor={id}>
      <span className="parity-field__label">{label}</span>
      <span className="parity-field__control">
        {props.as === "select" ? (
          <select
            id={id}
            className="parity-field__input parity-field__select"
            value={props.value}
            onChange={(event) => props.onChange?.(event.target.value)}
            disabled={props.disabled}
          >
            {props.options.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        ) : props.as === "textarea" ? (
          <textarea
            id={id}
            className="parity-field__input parity-field__textarea"
            value={props.value}
            onChange={props.onChange}
            placeholder={props.placeholder}
            rows={props.rows}
          />
        ) : (
          <input
            id={id}
            className="parity-field__input"
            type={props.type}
            value={props.value}
            onChange={props.onChange}
            placeholder={props.placeholder}
            autoComplete={props.autoComplete}
            inputMode={props.inputMode}
            disabled={props.disabled}
            readOnly={props.readOnly}
          />
        )}
        {suffix ? <span className="parity-field__suffix">{suffix}</span> : null}
      </span>
    </label>
  );
}
