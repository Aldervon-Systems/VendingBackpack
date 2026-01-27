# ATOMIC PLAN: Manager Registration

## Step 1: Update SessionManager signup [DONE]
- **Action**: Modify `Frontend/lib/modules/auth/SessionManager.dart`.
- **Change**: Add `String role = 'employee'` parameter to `signup` method. Pass it to the API.
- **Verification**: None (internal change).

## Step 2: Update AccessScreens state [DONE]
- **Action**: Modify `Frontend/lib/modules/auth/AccessScreens.dart`.
- **Change**: Add `String _selectedRole = 'employee'` to `_AccessScreensState`.
- **Verification**: None.

## Step 3: Update AccessScreens UI [DONE]
- **Action**: Modify `Frontend/lib/modules/auth/AccessScreens.dart`.
- **Change**: Add a `DropdownButtonFormField` or similar to select between 'Employee' and 'Manager' in registration mode.
- **Verification**: Visual check.

## Step 4: Update AccessScreens submission [DONE]
- **Action**: Modify `Frontend/lib/modules/auth/AccessScreens.dart`.
- **Change**: Update `_handleSubmit` to pass `_selectedRole` to `signup`.
- **Verification**: Try registering a manager and check local state / logs.
