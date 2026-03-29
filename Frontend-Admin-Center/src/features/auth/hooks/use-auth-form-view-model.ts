"use client";

import { useMemo, useState } from "react";
import { LocalAdminAuthRepository } from "@/features/auth/lib/admin-auth-repository";

const adminAuthRepository = new LocalAdminAuthRepository();

export function useAuthFormViewModel() {
  const authSeed = useMemo(() => adminAuthRepository.getAuthSeed(), []);
  const [error, setError] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [formState, setFormState] = useState({
    email: authSeed.defaultEmail,
    passphrase: authSeed.defaultPassphrase,
    shiftNote: authSeed.defaultShiftNote,
  });

  return {
    authSeed,
    error,
    isSubmitting,
    formState,
    setError,
    setIsSubmitting,
    setFormState,
    loadAccessCredentials() {
      setFormState({
        email: authSeed.defaultEmail,
        passphrase: authSeed.defaultPassphrase,
        shiftNote: authSeed.defaultShiftNote,
      });
      setError("");
    },
  };
}
