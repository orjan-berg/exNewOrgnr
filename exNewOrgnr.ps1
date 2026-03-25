function new-exOrgnr {
    param (
        [string]$endPoint = 'https://data.brreg.no/enhetsregisteret/api/enheter/',
        [int]$count = 1  # Number of organization numbers to generate
    )

    function new-NorwegianOrgUnitCheckDigit {
        param (
            [string]$orgUnitNumber
        )

        $normalized = $orgUnitNumber -replace '[\s.]+', ''
        if ($normalized.Length -ne 8) {
            throw 'Input must be 8 digits long.'
        }

        $weights = @(3, 2, 7, 6, 5, 4, 3, 2)
        $sum = 0
        for ($i = 0; $i -lt 8; $i++) {
            $sum += [int]::Parse($normalized[$i]) * $weights[$i]
        }

        $remainder = $sum % 11
        $checkDigit = if ($remainder -eq 0) { 0 } else { 11 - $remainder }

        return $checkDigit
    }

    function New-8DigitNumber {
        $random = Get-Random -Minimum 10000000 -Maximum 99999999
        return $random
    }

    $results = @()  # Array to hold results

    for ($i = 0; $i -lt $count; $i++) {

        # Trekker et nytt tall helt til vi får et gyldig kontrollsiffer (ikke 10)
        do {
            $randomNumber = New-8DigitNumber
            $checkDigit = new-NorwegianOrgUnitCheckDigit -orgUnitNumber $randomNumber
        } while ($checkDigit -eq 10)

        $orgnr = "$randomNumber$checkDigit"
        $uri = ($endPoint + $orgnr)

        try {
            $result = Invoke-RestMethod -Uri $uri -Method Get
            $results += $result
        } catch {
            # Handle expected responses as informational rather than errors
            switch ($_.Exception.Response.StatusCode.Value__) {
                400 { Write-Error "Error 400: Ugyldig format på orgnr ($orgnr)." }
                404 { Write-Host "Info: $orgnr finnes ikke i brreg, kan brukes." -ForegroundColor Yellow }
                410 { Write-Host "Info: $orgnr er slettet fra brreg, kan brukes." -ForegroundColor DarkYellow }
                500 { Write-Error 'Error 500: Server error.' }
                default { Write-Error "An unexpected error occurred: $_" }
            }
        }
    }

    return $results
}

# Eksempel på bruk:
# $results = new-exOrgnr -count 5
# Write-Output $results