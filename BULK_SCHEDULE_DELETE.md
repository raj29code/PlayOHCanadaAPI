# Bulk Schedule Deletion - Admin Endpoints

## Overview

New endpoints have been added to allow admins to delete all schedules they created in bulk, instead of deleting them one by one.

## New Endpoints

### 1. Delete My Schedules
**Endpoint:** `DELETE /api/schedules/my-schedules`  
**Auth:** Admin only  
**Description:** Delete all schedules created by the currently authenticated admin

### 2. Delete Schedules by Admin ID
**Endpoint:** `DELETE /api/schedules/admin/{adminId}`  
**Auth:** Admin only (can only delete own schedules)  
**Description:** Delete all schedules created by a specific admin

## Why These Endpoints?

### Problem
- Admin creates 50 recurring schedules
- Needs to delete all of them
- Has to call DELETE 50 times (inefficient)

### Solution
- One API call deletes all schedules
- Faster and more efficient
- Returns count of deleted items

## Endpoint Details

### DELETE /api/schedules/my-schedules

Delete all schedules created by the currently authenticated admin.

**Authentication:** Required (Admin role)

**Request:**
```http
DELETE /api/schedules/my-schedules
Authorization: Bearer YOUR_ADMIN_TOKEN
```

**Response (200 OK):**
```json
{
  "message": "All schedules deleted successfully",
  "deletedSchedules": 15,
  "affectedBookings": 42
}
```

**Response (404 Not Found):**
```json
{
  "message": "No schedules found for this admin"
}
```

**Response (401 Unauthorized):**
```json
{
  "message": "Unauthorized"
}
```

---

### DELETE /api/schedules/admin/{adminId}

Delete all schedules created by a specific admin.

**Authentication:** Required (Admin role, can only delete own schedules)

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `adminId` | int | Yes | Admin user ID |

**Request:**
```http
DELETE /api/schedules/admin/5
Authorization: Bearer YOUR_ADMIN_TOKEN
```

**Response (200 OK):**
```json
{
  "message": "All schedules by admin 5 deleted successfully",
  "deletedSchedules": 20,
  "affectedBookings": 58
}
```

**Response (403 Forbidden):**
```json
{
  "message": "You can only delete your own schedules"
}
```

**Response (404 Not Found):**
```json
{
  "message": "No schedules found for admin ID 5"
}
```

---

## Usage Examples

### JavaScript/Frontend

```javascript
async function deleteAllMySchedules(token) {
  const response = await fetch('/api/schedules/my-schedules', {
    method: 'DELETE',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json'
    }
  });
  
  if (response.ok) {
    const result = await response.json();
    console.log(`Deleted ${result.deletedSchedules} schedules`);
    console.log(`Affected ${result.affectedBookings} bookings`);
    return result;
  } else {
    throw new Error('Failed to delete schedules');
  }
}

// Usage
try {
  const result = await deleteAllMySchedules(adminToken);
  alert(`Successfully deleted ${result.deletedSchedules} schedules`);
} catch (error) {
  alert('Error deleting schedules');
}
```

### PowerShell

```powershell
# Login as admin
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "https://localhost:7063/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.token

# Delete all schedules created by this admin
$headers = @{
    "Authorization" = "Bearer $token"
}

$result = Invoke-RestMethod -Uri "https://localhost:7063/api/schedules/my-schedules" `
    -Method Delete -Headers $headers

Write-Host "Deleted $($result.deletedSchedules) schedules"
Write-Host "Affected $($result.affectedBookings) bookings"
```

### cURL

```bash
# Delete all schedules created by authenticated admin
curl -X DELETE https://localhost:7063/api/schedules/my-schedules \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -k

# Delete schedules by specific admin ID
curl -X DELETE https://localhost:7063/api/schedules/admin/5 \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -k
```

## Security Features

### Authorization

1. **Admin Only** - Only users with Admin role can access these endpoints
2. **Own Schedules Only** - Admins can only delete their own schedules
3. **Token Validation** - JWT token must be valid and not blacklisted

### Future Enhancement

For super admin role (not yet implemented):
```csharp
// Check if user is super admin
if (User.IsInRole(UserRoles.SuperAdmin))
{
    // Allow deleting any admin's schedules
}
else if (currentAdminId != adminId)
{
    return Forbid("You can only delete your own schedules");
}
```

## Response Information

### Success Response

The response includes:

| Field | Type | Description |
|-------|------|-------------|
| `message` | string | Success message |
| `deletedSchedules` | int | Number of schedules deleted |
| `affectedBookings` | int | Number of bookings that were cascade deleted |

**Example:**
```json
{
  "message": "All schedules deleted successfully",
  "deletedSchedules": 15,
  "affectedBookings": 42
}
```

This information is useful for:
- ? Confirming the operation
- ? Logging/auditing
- ? Showing feedback to admin
- ? Understanding impact (how many users affected)

## Use Cases

### Use Case 1: Testing/Development

**Scenario:** Admin created test schedules and wants to clean up

```javascript
// Quick cleanup during development
await fetch('/api/schedules/my-schedules', {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${token}` }
});
```

### Use Case 2: Venue Closure

**Scenario:** A venue permanently closes, admin needs to delete all schedules

```javascript
async function cleanupVenueSchedules() {
  const result = await fetch('/api/schedules/my-schedules', {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  
  const data = await result.json();
  
  // Notify users (future feature)
  await notifyAffectedUsers(data.affectedBookings);
}
```

### Use Case 3: Admin Leaving

**Scenario:** Admin is leaving organization, need to clean up their schedules

```javascript
// Super admin deletes all schedules by departing admin
await fetch(`/api/schedules/admin/${departingAdminId}`, {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${superAdminToken}` }
});
```

## Cascade Deletion

When schedules are deleted:

1. **Schedules** ? Deleted from database
2. **Bookings** ? Automatically deleted (cascade delete)
3. **Users** ? Remain unchanged (booking history lost)

### Database Impact

**Before:**
```
Admin creates 20 schedules
Users make 50 bookings
```

**After bulk delete:**
```
20 schedules deleted
50 bookings automatically deleted
Database space freed
```

## Comparison: Single vs Bulk Delete

### Single Delete (Old Way)

```javascript
// Delete 20 schedules one by one
for (const schedule of schedules) {
  await fetch(`/api/schedules/${schedule.id}`, {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` }
  });
}
// 20 API calls, slow, inefficient
```

**Issues:**
- ? 20 separate API calls
- ? Slow (network latency × 20)
- ? Error-prone (one fails, others continue)
- ? No transaction (partial success possible)

### Bulk Delete (New Way)

```javascript
// Delete all 20 schedules at once
await fetch('/api/schedules/my-schedules', {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${token}` }
});
// 1 API call, fast, atomic
```

**Benefits:**
- ? Single API call
- ? Fast (one network round-trip)
- ? Atomic operation (all or nothing)
- ? Consistent state

## Testing

### Test Script

```powershell
# Test bulk delete functionality

Write-Host "=== Testing Bulk Schedule Deletion ===" -ForegroundColor Cyan

# 1. Login as admin
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$token = $loginResponse.token
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

# 2. Create some test schedules
Write-Host "Creating 5 test schedules..." -ForegroundColor Yellow

$createBody = @{
    sportId = 1
    venue = "Test Venue"
    startDate = "2026-06-01"
    startTime = "19:00:00"
    endTime = "20:00:00"
    maxPlayers = 8
    timezoneOffsetMinutes = -300
    recurrence = @{
        isRecurring = $true
        frequency = 1  # Daily
        endDate = "2026-06-05"
    }
} | ConvertTo-Json -Depth 10

$schedules = Invoke-RestMethod -Uri "http://localhost:5000/api/schedules" `
    -Method Post -Headers $headers -Body $createBody

Write-Host "Created $($schedules.Count) schedules" -ForegroundColor Green

# 3. Delete all schedules
Write-Host "`nDeleting all schedules..." -ForegroundColor Yellow

$deleteResult = Invoke-RestMethod -Uri "http://localhost:5000/api/schedules/my-schedules" `
    -Method Delete -Headers $headers

Write-Host "Deleted $($deleteResult.deletedSchedules) schedules" -ForegroundColor Green
Write-Host "Affected $($deleteResult.affectedBookings) bookings" -ForegroundColor Green

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
```

### Manual Testing with Scalar UI

1. **Create schedules:**
   - POST `/api/schedules` with recurring settings
   - Create 10-20 schedules

2. **Verify schedules exist:**
   - GET `/api/schedules`
   - Confirm they show up

3. **Bulk delete:**
   - DELETE `/api/schedules/my-schedules`
   - Note the response (count deleted)

4. **Verify deletion:**
   - GET `/api/schedules`
   - Confirm they're gone

## Limitations

### Current Limitations

1. **No Undo** - Deletion is permanent
2. **No Selective Delete** - Deletes ALL schedules by admin
3. **No Date Filter** - Can't delete only old schedules
4. **No Notification** - Users aren't notified (TODO)

### Future Enhancements

**Selective Bulk Delete:**
```csharp
// Delete schedules by criteria
DELETE /api/schedules/bulk?venue=Tennis&before=2026-02-01
```

**Soft Delete:**
```csharp
// Mark as deleted instead of removing
DELETE /api/schedules/my-schedules?soft=true
```

**Notification Support:**
```csharp
// Send emails to affected users
DELETE /api/schedules/my-schedules?notify=true
```

## Error Handling

### Common Errors

**401 Unauthorized:**
```json
{
  "message": "Unauthorized"
}
```
**Cause:** Invalid or missing token  
**Solution:** Login and get valid admin token

**403 Forbidden:**
```json
{
  "message": "You can only delete your own schedules"
}
```
**Cause:** Trying to delete another admin's schedules  
**Solution:** Use `/my-schedules` or correct admin ID

**404 Not Found:**
```json
{
  "message": "No schedules found for this admin"
}
```
**Cause:** Admin has no schedules to delete  
**Solution:** This is okay, no action needed

## Best Practices

### ? DO:

1. **Confirm before delete** - Show warning to user
2. **Log the operation** - Track who deleted what
3. **Show impact** - Display affected bookings count
4. **Provide feedback** - Show success/error message

### ? DON'T:

1. **Don't delete without confirmation** - Too risky
2. **Don't ignore response** - Check deleted count
3. **Don't assume success** - Handle errors
4. **Don't forget users** - They'll be affected

### Example Confirmation UI

```javascript
async function deleteAllSchedulesWithConfirmation() {
  // 1. Get count first
  const schedules = await fetch('/api/schedules?sportId=1').then(r => r.json());
  const count = schedules.length;
  
  // 2. Show confirmation
  const confirmed = confirm(
    `Are you sure you want to delete ${count} schedules? ` +
    `This will also cancel all bookings and cannot be undone.`
  );
  
  if (!confirmed) return;
  
  // 3. Delete
  try {
    const result = await fetch('/api/schedules/my-schedules', {
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${token}` }
    }).then(r => r.json());
    
    // 4. Show result
    alert(
      `Successfully deleted ${result.deletedSchedules} schedules. ` +
      `${result.affectedBookings} bookings were canceled.`
    );
  } catch (error) {
    alert('Error deleting schedules. Please try again.');
  }
}
```

## Summary

### New Endpoints

? **DELETE `/api/schedules/my-schedules`** - Delete all my schedules  
? **DELETE `/api/schedules/admin/{adminId}`** - Delete schedules by admin ID  

### Benefits

? **Efficient** - One API call vs many  
? **Fast** - Single transaction  
? **Atomic** - All or nothing  
? **Informative** - Returns deletion stats  

### Use Cases

? **Testing cleanup** - Remove test data quickly  
? **Venue closure** - Delete all schedules at once  
? **Admin departure** - Clean up when admin leaves  

### Next Steps

1. **Test the endpoints** using Scalar UI or scripts
2. **Implement UI confirmation** before deletion
3. **Add notification system** (future) to alert users
4. **Consider soft delete** (future) for recoverability

---

**Now admins can efficiently delete all their schedules with a single API call!** ????
