# Save as get-otp.ps1 and run from project root
param(
  [Parameter(Mandatory=$true)][ValidateSet("senior-register","volunteer-register","user-login","admin-login")] [string]$flow,
  [Parameter(Mandatory=$true)] [string]$phone,
  [string]$name = "Test User",
  [string]$occupation = "Volunteer",
  [string]$password = "Admin@123",
  [string]$baseUrl = "http://127.0.0.1:3000"
)

function Post-Json($url, $body) {
  return Invoke-RestMethod -Method Post -Uri $url -ContentType "application/json" -Body ($body | ConvertTo-Json)
}

try {
  switch ($flow) {
    "senior-register" {
      $res = Post-Json "$baseUrl/api/auth/register-senior" @{ name=$name; phone=$phone }
    }
    "volunteer-register" {
      $res = Post-Json "$baseUrl/api/auth/register-volunteer" @{ name=$name; phone=$phone; occupation=$occupation }
    }
    "user-login" {
      $res = Post-Json "$baseUrl/api/auth/login/send-otp" @{ phone=$phone }
    }
    "admin-login" {
      $res = Post-Json "$baseUrl/api/auth/admin/login/send-otp" @{ phone=$phone; password=$password }
    }
  }

  Write-Host "Message: $($res.message)"
  Write-Host "OTP: $($res.otp)"
}
catch {
  if ($_.Exception.Response -ne $null) {
    $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
    $errBody = $reader.ReadToEnd()
    Write-Host "Error: $errBody"
  } else {
    Write-Host "Error: $($_.Exception.Message)"
  }
}
