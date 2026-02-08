# Update Sport API - Complete Guide

## Overview

The Sports API now includes an UPDATE endpoint allowing admins to modify existing sports.

## New Endpoint

### PUT /api/sports/{id}

Update an existing sport's name and/or icon URL.

**Authentication:** Admin only

**Parameters:**
- `id` (path) - Sport ID to update

**Request Body:**
```json
{
  "name": "Tennis",           // Optional - new name
  "iconUrl": "https://..."    // Optional - new icon URL
}
```

**Both fields are optional** - only provide the fields you want to update.

---

## Usage Examples

### Example 1: Update Sport Name

**Request:**
```http
PUT /api/sports/1
Content-Type: application/json
Authorization: Bearer {admin-token}

{
  "name": "Table Tennis"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Table Tennis",
  "iconUrl": "https://example.com/tennis.png"
}
```

### Example 2: Update Icon URL

**Request:**
```http
PUT /api/sports/1
Content-Type: application/json
Authorization: Bearer {admin-token}

{
  "iconUrl": "https://example.com/new-icon.png"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Tennis",
  "iconUrl": "https://example.com/new-icon.png"
}
```

### Example 3: Update Both

**Request:**
```http
PUT /api/sports/1
Content-Type: application/json
Authorization: Bearer {admin-token}

{
  "name": "Table Tennis",
  "iconUrl": "https://example.com/table-tennis.png"
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Table Tennis",
  "iconUrl": "https://example.com/table-tennis.png"
}
```

### Example 4: Clear Icon URL

**Request:**
```http
PUT /api/sports/1
Content-Type: application/json
Authorization: Bearer {admin-token}

{
  "iconUrl": ""
}
```

**Response (200 OK):**
```json
{
  "id": 1,
  "name": "Tennis",
  "iconUrl": ""
}
```

---

## Error Responses

### 404 Not Found

**When:** Sport with specified ID doesn't exist

```json
{
  "message": "Sport not found"
}
```

### 400 Bad Request - Duplicate Name

**When:** New name already exists for another sport

```json
{
  "message": "A sport with this name already exists"
}
```

### 401 Unauthorized

**When:** No authentication token provided

```json
{
  "message": "Unauthorized"
}
```

### 403 Forbidden

**When:** User is not an admin

```json
{
  "message": "Forbidden"
}
```

---

## JavaScript/TypeScript Examples

### Fetch API

```javascript
async function updateSport(sportId, updates, adminToken) {
  const response = await fetch(`/api/sports/${sportId}`, {
    method: 'PUT',
    headers: {
      'Authorization': `Bearer ${adminToken}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(updates)
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return await response.json();
}

// Usage examples
await updateSport(1, { name: "Table Tennis" }, adminToken);
await updateSport(1, { iconUrl: "https://..." }, adminToken);
await updateSport(1, { name: "Badminton", iconUrl: "https://..." }, adminToken);
```

### Axios

```javascript
import axios from 'axios';

async function updateSport(sportId, updates, adminToken) {
  try {
    const response = await axios.put(
      `/api/sports/${sportId}`,
      updates,
      {
        headers: {
          'Authorization': `Bearer ${adminToken}`
        }
      }
    );
    return response.data;
  } catch (error) {
    console.error('Error updating sport:', error.response.data);
    throw error;
  }
}

// Usage
await updateSport(1, { name: "Table Tennis" }, adminToken);
```

---

## React Component Example

```jsx
import { useState } from 'react';

function EditSportForm({ sport, onUpdate, adminToken }) {
  const [name, setName] = useState(sport.name);
  const [iconUrl, setIconUrl] = useState(sport.iconUrl || '');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      const updates = {};
      
      // Only include changed fields
      if (name !== sport.name) {
        updates.name = name;
      }
      if (iconUrl !== sport.iconUrl) {
        updates.iconUrl = iconUrl;
      }

      if (Object.keys(updates).length === 0) {
        alert('No changes to save');
        setLoading(false);
        return;
      }

      const response = await fetch(`/api/sports/${sport.id}`, {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${adminToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(updates)
      });

      if (!response.ok) {
        const error = await response.json();
        throw new Error(error.message);
      }

      const updatedSport = await response.json();
      onUpdate(updatedSport);
      alert('Sport updated successfully!');
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <h2>Edit Sport</h2>
      
      {error && <div className="error">{error}</div>}
      
      <div>
        <label>Name:</label>
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
        />
      </div>
      
      <div>
        <label>Icon URL:</label>
        <input
          type="url"
          value={iconUrl}
          onChange={(e) => setIconUrl(e.target.value)}
          placeholder="https://example.com/icon.png"
        />
      </div>
      
      <button type="submit" disabled={loading}>
        {loading ? 'Updating...' : 'Update Sport'}
      </button>
    </form>
  );
}
```

---

## Vue Component Example

```vue
<template>
  <form @submit.prevent="handleSubmit">
    <h2>Edit Sport</h2>
    
    <div v-if="error" class="error">{{ error }}</div>
    
    <div>
      <label>Name:</label>
      <input v-model="name" type="text" required />
    </div>
    
    <div>
      <label>Icon URL:</label>
      <input v-model="iconUrl" type="url" placeholder="https://..." />
    </div>
    
    <button type="submit" :disabled="loading">
      {{ loading ? 'Updating...' : 'Update Sport' }}
    </button>
  </form>
</template>

<script>
export default {
  props: ['sport', 'adminToken'],
  emits: ['update'],
  data() {
    return {
      name: this.sport.name,
      iconUrl: this.sport.iconUrl || '',
      loading: false,
      error: null
    };
  },
  methods: {
    async handleSubmit() {
      this.loading = true;
      this.error = null;

      try {
        const updates = {};
        
        if (this.name !== this.sport.name) {
          updates.name = this.name;
        }
        if (this.iconUrl !== this.sport.iconUrl) {
          updates.iconUrl = this.iconUrl;
        }

        if (Object.keys(updates).length === 0) {
          alert('No changes to save');
          this.loading = false;
          return;
        }

        const response = await fetch(`/api/sports/${this.sport.id}`, {
          method: 'PUT',
          headers: {
            'Authorization': `Bearer ${this.adminToken}`,
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(updates)
        });

        if (!response.ok) {
          const error = await response.json();
          throw new Error(error.message);
        }

        const updatedSport = await response.json();
        this.$emit('update', updatedSport);
        alert('Sport updated successfully!');
      } catch (err) {
        this.error = err.message;
      } finally {
        this.loading = false;
      }
    }
  }
};
</script>
```

---

## PowerShell Examples

### Update Sport Name

```powershell
$adminToken = "your-admin-token"
$sportId = 1

$headers = @{
    "Authorization" = "Bearer $adminToken"
}

$body = @{
    name = "Table Tennis"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/sports/$sportId" `
    -Method Put `
    -Headers $headers `
    -Body $body `
    -ContentType "application/json"

Write-Host "Updated sport: $($response.name)"
```

### Update Icon URL

```powershell
$body = @{
    iconUrl = "https://example.com/new-icon.png"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/sports/$sportId" `
    -Method Put `
    -Headers $headers `
    -Body $body `
    -ContentType "application/json"

Write-Host "Updated icon URL"
```

### Update Both Fields

```powershell
$body = @{
    name = "Badminton"
    iconUrl = "https://example.com/badminton.png"
} | ConvertTo-Json

$response = Invoke-RestMethod -Uri "https://localhost:7063/api/sports/$sportId" `
    -Method Put `
    -Headers $headers `
    -Body $body `
    -ContentType "application/json"

Write-Host "Sport updated:"
Write-Host "  Name: $($response.name)"
Write-Host "  Icon: $($response.iconUrl)"
```

---

## cURL Examples

### Update Name

```bash
curl -X PUT https://localhost:7063/api/sports/1 \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"name":"Table Tennis"}' \
  -k
```

### Update Icon

```bash
curl -X PUT https://localhost:7063/api/sports/1 \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{"iconUrl":"https://example.com/icon.png"}' \
  -k
```

### Update Both

```bash
curl -X PUT https://localhost:7063/api/sports/1 \
  -H "Authorization: Bearer ${ADMIN_TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Badminton",
    "iconUrl":"https://example.com/badminton.png"
  }' \
  -k
```

---

## Use Cases

### Use Case 1: Fix Typo in Sport Name

**Scenario:** Admin realizes "Tenis" should be "Tennis"

```javascript
await updateSport(5, { name: "Tennis" }, adminToken);
```

**Impact:** All schedules for this sport now show correct name

### Use Case 2: Update Icon to Better Quality

**Scenario:** Found a higher quality icon

```javascript
await updateSport(1, {
  iconUrl: "https://cdn.example.com/tennis-hd.png"
}, adminToken);
```

**Impact:** All schedules show new icon immediately

### Use Case 3: Rebrand Sport Name

**Scenario:** Change "Ping Pong" to "Table Tennis" for consistency

```javascript
await updateSport(3, { name: "Table Tennis" }, adminToken);
```

**Impact:** All schedules and UI updated

### Use Case 4: Add Icon to Sport Without One

**Scenario:** Initially created sport without icon

```javascript
await updateSport(2, {
  iconUrl: "https://example.com/basketball.png"
}, adminToken);
```

---

## Validation Rules

### Name Validation

? **Valid:**
- Any non-empty string
- Can update to same name (no change)
- Unique across all sports

? **Invalid:**
- Name already exists for another sport
- Empty string (if provided)

### Icon URL Validation

? **Valid:**
- Valid URL string
- Empty string (clears icon)
- Null (no change)

? **Invalid:**
- Invalid URL format (browser validation)

---

## Impact on Schedules

### Important: Changes Propagate Immediately

When you update a sport, **all existing schedules** for that sport are automatically updated:

```javascript
// Update sport name
await updateSport(1, { name: "Table Tennis" }, adminToken);

// All schedules now show "Table Tennis"
const schedules = await fetch('/api/schedules?sportId=1').then(r => r.json());
// schedules[0].sportName === "Table Tennis" ?
```

**Why?** Schedules reference sports by ID (foreign key), so changes to the Sport entity are reflected everywhere.

---

## Complete Sports CRUD API

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| GET | `/api/sports` | Get all sports | None |
| GET | `/api/sports/{id}` | Get sport by ID | None |
| POST | `/api/sports` | Create new sport | Admin |
| **PUT** | **`/api/sports/{id}`** | **Update sport** | **Admin** |
| DELETE | `/api/sports/{id}` | Delete sport | Admin |

---

## Testing

### Test Script

```powershell
# Test Update Sport Endpoint

$baseUrl = "https://localhost:7063"

# Login as admin
$loginBody = @{
    email = "admin@playohcanada.com"
    password = "Admin@123"
} | ConvertTo-Json

$login = Invoke-RestMethod -Uri "$baseUrl/api/auth/login" `
    -Method Post -Body $loginBody -ContentType "application/json"

$adminToken = $login.token
$headers = @{ "Authorization" = "Bearer $adminToken" }

# Create a test sport
$createBody = @{
    name = "Test Sport"
    iconUrl = "https://example.com/test.png"
} | ConvertTo-Json

$sport = Invoke-RestMethod -Uri "$baseUrl/api/sports" `
    -Method Post -Headers $headers -Body $createBody -ContentType "application/json"

Write-Host "Created sport: $($sport.name) (ID: $($sport.id))"

# Test 1: Update name
$updateBody = @{
    name = "Updated Sport"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "$baseUrl/api/sports/$($sport.id)" `
    -Method Put -Headers $headers -Body $updateBody -ContentType "application/json"

Write-Host "Updated name: $($updated.name)" # "Updated Sport"

# Test 2: Update icon
$updateBody = @{
    iconUrl = "https://example.com/new-icon.png"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "$baseUrl/api/sports/$($sport.id)" `
    -Method Put -Headers $headers -Body $updateBody -ContentType "application/json"

Write-Host "Updated icon: $($updated.iconUrl)" # New URL

# Test 3: Update both
$updateBody = @{
    name = "Final Sport"
    iconUrl = "https://example.com/final.png"
} | ConvertTo-Json

$updated = Invoke-RestMethod -Uri "$baseUrl/api/sports/$($sport.id)" `
    -Method Put -Headers $headers -Body $updateBody -ContentType "application/json"

Write-Host "Final update:"
Write-Host "  Name: $($updated.name)"
Write-Host "  Icon: $($updated.iconUrl)"

# Test 4: Try duplicate name (should fail)
$duplicateBody = @{
    name = "Tennis"  # Assuming this exists
} | ConvertTo-Json

try {
    Invoke-RestMethod -Uri "$baseUrl/api/sports/$($sport.id)" `
        -Method Put -Headers $headers -Body $duplicateBody -ContentType "application/json"
} catch {
    Write-Host "? Correctly prevented duplicate name"
}

# Clean up
Invoke-RestMethod -Uri "$baseUrl/api/sports/$($sport.id)" `
    -Method Delete -Headers $headers
```

---

## Summary

### What Was Added

? **PUT /api/sports/{id}** endpoint  
? **UpdateSportDto** model  
? **Partial updates** - only update provided fields  
? **Duplicate name validation**  
? **Impact on all schedules** - changes propagate immediately  

### Key Features

? **Flexible** - Update name, icon, or both  
? **Validated** - Prevents duplicate names  
? **Safe** - Admin-only access  
? **Immediate** - Changes reflect everywhere  
? **Optional fields** - Only update what you want  

### Use Cases

? Fix typos in sport names  
? Update icons to better quality  
? Rebrand sport names  
? Add missing icons  
? Clear icons  

---

**Now admins can easily update sports without deleting and recreating them!** ?????
