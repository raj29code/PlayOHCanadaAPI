# Bulk Schedule Deletion - Implementation Summary

## ? What Was Implemented

Two new endpoints have been added to allow admins to delete all their schedules in bulk.

## New Endpoints

### 1. DELETE /api/schedules/my-schedules
**Purpose:** Delete all schedules created by the currently authenticated admin

**Features:**
- ? Requires admin authentication
- ? Deletes only schedules created by authenticated admin
- ? Returns count of deleted schedules and affected bookings
- ? Atomic operation (all or nothing)
- ? Cascade deletes associated bookings

**Response:**
```json
{
  "message": "All schedules deleted successfully",
  "deletedSchedules": 15,
  "affectedBookings": 42
}
```

### 2. DELETE /api/schedules/admin/{adminId}
**Purpose:** Delete all schedules created by a specific admin

**Features:**
- ? Requires admin authentication
- ? Security: Admins can only delete their own schedules
- ? Returns count of deleted schedules and affected bookings
- ? Ready for future super admin enhancement
- ? Cascade deletes associated bookings

**Response:**
```json
{
  "message": "All schedules by admin 5 deleted successfully",
  "deletedSchedules": 20,
  "affectedBookings": 58
}
```

## Implementation Details

### Controller Changes

**File:** `PlayOhCanadaAPI\Controllers\SchedulesController.cs`

**Added Methods:**
1. `DeleteMySchedules()` - Bulk delete for current admin
2. `DeleteSchedulesByAdmin(int adminId)` - Bulk delete for specific admin

**Key Features:**
- Admin ID extraction from JWT claims
- Authorization checks (own schedules only)
- Count tracking (schedules and bookings)
- Informative responses
- Cascade deletion handling

### Code Example

```csharp
[HttpDelete("my-schedules")]
[Authorize(Roles = UserRoles.Admin)]
public async Task<IActionResult> DeleteMySchedules()
{
    var adminIdStr = User.FindFirstValue(ClaimTypes.NameIdentifier);
    if (!int.TryParse(adminIdStr, out int adminId))
    {
        return Unauthorized();
    }

    var schedules = await _context.Schedules
        .Include(s => s.Bookings)
        .Where(s => s.CreatedByAdminId == adminId)
        .ToListAsync();

    if (!schedules.Any())
    {
        return NotFound(new { message = "No schedules found for this admin" });
    }

    var totalSchedules = schedules.Count;
    var totalBookings = schedules.Sum(s => s.Bookings.Count);

    _context.Schedules.RemoveRange(schedules);
    await _context.SaveChangesAsync();

    return Ok(new
    {
        message = "All schedules deleted successfully",
        deletedSchedules = totalSchedules,
        affectedBookings = totalBookings
    });
}
```

## Use Cases

### 1. Testing/Development Cleanup
**Scenario:** Admin created test data and needs to clean up

```javascript
await fetch('/api/schedules/my-schedules', {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${token}` }
});
```

### 2. Venue Closure
**Scenario:** A venue permanently closes

```javascript
const result = await deleteAllMySchedules();
console.log(`Deleted ${result.deletedSchedules} schedules`);
```

### 3. Admin Departure
**Scenario:** Admin leaving organization

```javascript
// Future: Super admin can delete any admin's schedules
await fetch(`/api/schedules/admin/${departingAdminId}`, {
  method: 'DELETE',
  headers: { 'Authorization': `Bearer ${superAdminToken}` }
});
```

## Benefits

### Efficiency
**Before (Individual Delete):**
```javascript
// Delete 50 schedules one by one
for (const schedule of schedules) {
  await fetch(`/api/schedules/${schedule.id}`, { method: 'DELETE' });
}
// 50 API calls, slow, error-prone
```

**After (Bulk Delete):**
```javascript
// Delete all 50 schedules at once
await fetch('/api/schedules/my-schedules', { method: 'DELETE' });
// 1 API call, fast, atomic
```

### Comparison

| Aspect | Individual Delete | Bulk Delete |
|--------|------------------|-------------|
| **API Calls** | N calls (one per schedule) | 1 call |
| **Speed** | Slow (N × latency) | Fast (1 × latency) |
| **Atomic** | No (partial success) | Yes (all or nothing) |
| **Error Handling** | Complex | Simple |
| **Network Traffic** | High | Low |

## Security

### Authorization Checks

1. **Admin Role Required** - Only admin users can access
2. **Token Validation** - JWT must be valid and not blacklisted
3. **Own Schedules Only** - Admin can only delete their own schedules
4. **Admin ID Verification** - Extracted from JWT claims

### Security Flow

```
1. User makes DELETE request
   ?
2. JWT token validated
   ?
3. Check if user has Admin role
   ?
4. Extract admin ID from token
   ?
5. Verify admin ID matches target
   ?
6. Delete schedules
```

## Response Information

### Success Response (200 OK)

```json
{
  "message": "All schedules deleted successfully",
  "deletedSchedules": 15,
  "affectedBookings": 42
}
```

**Fields:**
- `message` - Success message
- `deletedSchedules` - Number of schedules deleted
- `affectedBookings` - Number of bookings cascade deleted

### Error Responses

**401 Unauthorized:**
```json
{
  "message": "Unauthorized"
}
```
**Cause:** Invalid or missing token

**403 Forbidden:**
```json
{
  "message": "You can only delete your own schedules"
}
```
**Cause:** Trying to delete another admin's schedules

**404 Not Found:**
```json
{
  "message": "No schedules found for this admin"
}
```
**Cause:** Admin has no schedules to delete

## Database Impact

### Cascade Deletion

When bulk delete is performed:

```
Schedules ? Deleted
    ?
Bookings ? Automatically deleted (cascade)
    ?
Users ? Remain (not affected)
```

### Example

**Before:**
- 20 schedules in database
- 50 bookings associated with those schedules

**After bulk delete:**
- 0 schedules (all deleted)
- 0 bookings (cascade deleted)
- Database space freed

## Testing

### Test Script Created

**File:** `test-bulk-delete-schedules.ps1`

**Tests:**
1. ? Login as admin
2. ? Create test schedules (recurring)
3. ? Bulk delete using `/my-schedules`
4. ? Verify schedules deleted
5. ? Test 404 when no schedules exist
6. ? Bulk delete by admin ID
7. ? Test security (other admin's schedules)

**Run the test:**
```powershell
.\test-bulk-delete-schedules.ps1
```

### Manual Testing with Scalar UI

1. **Create schedules:**
   - POST `/api/schedules` with recurring settings
   - Create 10-20 test schedules

2. **Verify creation:**
   - GET `/api/schedules`
   - Confirm schedules exist

3. **Bulk delete:**
   - DELETE `/api/schedules/my-schedules`
   - Note the response counts

4. **Verify deletion:**
   - GET `/api/schedules`
   - Confirm schedules are gone

## Documentation

### Files Created

1. **BULK_SCHEDULE_DELETE.md** - Complete documentation
   - Overview and endpoints
   - Usage examples (JavaScript, PowerShell, cURL)
   - Security features
   - Use cases and comparisons
   - Testing instructions
   - Best practices

2. **test-bulk-delete-schedules.ps1** - Test script
   - Automated testing of all scenarios
   - Comprehensive validation

3. **BULK_SCHEDULE_DELETE_IMPLEMENTATION.md** - This file
   - Implementation summary
   - Technical details

## Future Enhancements

### Planned Features

1. **Notification System**
```csharp
// TODO: Implement notification system to alert users
// In production, send emails to all affected users
```

2. **Selective Bulk Delete**
```csharp
// Delete schedules with filters
DELETE /api/schedules/bulk?venue=Tennis&before=2026-02-01
```

3. **Soft Delete**
```csharp
// Mark as deleted instead of removing
DELETE /api/schedules/my-schedules?soft=true
```

4. **Super Admin Support**
```csharp
// Allow super admin to delete any admin's schedules
if (User.IsInRole(UserRoles.SuperAdmin))
{
    // Allow deletion of any admin's schedules
}
```

## API Reference Summary

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/schedules/{id}` | DELETE | Admin | Delete single schedule |
| `/api/schedules/my-schedules` | DELETE | Admin | Delete all my schedules |
| `/api/schedules/admin/{adminId}` | DELETE | Admin | Delete schedules by admin ID |

## Backward Compatibility

? **Fully backward compatible**

**Existing functionality:**
- Single schedule delete (`DELETE /schedules/{id}`) - Still works
- All GET endpoints - Unchanged
- POST/PUT endpoints - Unchanged

**New functionality:**
- Bulk delete endpoints added
- No breaking changes
- Optional feature

## Best Practices

### ? DO:

1. **Confirm before delete** - Show warning to user
2. **Display impact** - Show affected bookings count
3. **Log operations** - Track who deleted what
4. **Handle errors** - Check response status
5. **Provide feedback** - Show success/error messages

### ? DON'T:

1. **Don't delete without confirmation** - Too risky
2. **Don't ignore response** - Check deleted counts
3. **Don't assume success** - Handle errors properly
4. **Don't forget users** - They'll be affected by deletion

### Example Implementation

```javascript
async function deleteAllSchedulesWithConfirmation() {
  // 1. Get count first
  const schedules = await fetch('/api/schedules').then(r => r.json());
  const count = schedules.length;
  
  // 2. Confirm
  const confirmed = confirm(
    `Delete ${count} schedules? This will cancel all bookings.`
  );
  
  if (!confirmed) return;
  
  // 3. Delete
  const result = await fetch('/api/schedules/my-schedules', {
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${token}` }
  }).then(r => r.json());
  
  // 4. Show result
  alert(`Deleted ${result.deletedSchedules} schedules`);
}
```

## Build Status

? **Build Successful**

## Summary

### What Was Added

? **2 new DELETE endpoints** for bulk schedule deletion  
? **Security checks** - Own schedules only  
? **Informative responses** - Returns deletion counts  
? **Cascade deletion** - Automatically deletes bookings  
? **Complete documentation** - Guide and examples  
? **Test script** - Automated testing  

### Benefits

? **Efficient** - 1 API call instead of N  
? **Fast** - Single transaction  
? **Atomic** - All or nothing operation  
? **Secure** - Proper authorization  
? **Informative** - Clear feedback  

### Ready For

? Production deployment  
? Frontend integration  
? Testing and validation  

---

**Now admins can efficiently manage their schedules with bulk deletion!** ????
