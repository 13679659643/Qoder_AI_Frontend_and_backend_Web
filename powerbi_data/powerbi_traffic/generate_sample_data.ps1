$OutputDir = $PSScriptRoot

$brands = @("M Polo", "W Polo")
$fwMap = @{
    "M Polo" = @("Acceleration", "Foundation", "T-shirt", "Complemen")
    "W Polo" = @("Acceleration", "Foundation")
}
$adsFormats = @("ZTC", "YLMF", "QZT")

$startDate = Get-Date -Year 2026 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0
$endDate   = Get-Date -Year 2026 -Month 4 -Day 18 -Hour 0 -Minute 0 -Second 0

$rows = [System.Collections.ArrayList]::new()
$rand = New-Object System.Random(42)

$currentDate = $startDate
while ($currentDate -le $endDate) {
    foreach ($brand in $brands) {
        if ($brand -eq "M Polo") { $brandMul = 1.0 } else { $brandMul = 0.75 }

        foreach ($fw in $fwMap[$brand]) {
            switch ($fw) {
                "Acceleration" { $fwMul = 1.2 }
                "Foundation"   { $fwMul = 1.0 }
                "T-shirt"      { $fwMul = 0.6 }
                "Complemen"    { $fwMul = 0.4 }
                default        { $fwMul = 1.0 }
            }

            foreach ($ads in $adsFormats) {
                switch ($ads) {
                    "ZTC"  { $adsMul = 1.0 }
                    "YLMF" { $adsMul = 0.8 }
                    "QZT"  { $adsMul = 0.6 }
                    default { $adsMul = 1.0 }
                }

                $base = $brandMul * $fwMul * $adsMul
                $mon = $currentDate.Month
                switch ($mon) { 1{$sf=0.8} 2{$sf=0.7} 3{$sf=0.9} 4{$sf=1.1} default{$sf=1.0} }
                $dow = [int]$currentDate.DayOfWeek
                if ($dow -eq 0 -or $dow -eq 6) { $wf = 1.15 } else { $wf = 1.0 }
                $noise = 0.85 + ($rand.NextDouble() * 0.3)

                # Current period values
                $impression = [math]::Round(8000 * $base * $sf * $wf * $noise)
                $click = [math]::Round($impression * (0.03 + $rand.NextDouble() * 0.04))
                $cost = [math]::Round($click * (1.5 + $rand.NextDouble() * 2.0), 2)
                $orderCnt = [math]::Max(1, [math]::Round($click * (0.02 + $rand.NextDouble() * 0.06)))
                $payAmount = [math]::Round($orderCnt * (80 + $rand.NextDouble() * 220), 2)
                $ncRatio = 0.15 + $rand.NextDouble() * 0.25
                $newCustCnt = [math]::Max(1, [math]::Round($orderCnt * $ncRatio))
                $ncCostRatio = 0.3 + $rand.NextDouble() * 0.2
                $newCustCost = [math]::Round($cost * $ncCostRatio, 2)
                $ncPayRatio = 0.2 + $rand.NextDouble() * 0.15
                $newCustPayAmount = [math]::Round($payAmount * $ncPayRatio, 2)

                # LY values (last year, ~85-115% of current with noise)
                $lyFactor = 0.85 + $rand.NextDouble() * 0.3
                $costLy = [math]::Round($cost * $lyFactor, 2)
                $payAmountLy = [math]::Round($payAmount * (0.8 + $rand.NextDouble() * 0.35), 2)
                $newCustCntLy = [math]::Max(0, [math]::Round($newCustCnt * (0.75 + $rand.NextDouble() * 0.4)))
                $newCustCostLy = [math]::Round($newCustCost * (0.8 + $rand.NextDouble() * 0.35), 2)
                $newCustPayAmountLy = [math]::Round($newCustPayAmount * (0.75 + $rand.NextDouble() * 0.4), 2)

                # Target values (~95-110% of current)
                $tarFactor = 0.95 + $rand.NextDouble() * 0.15
                $costTarget = [math]::Round($cost * $tarFactor, 2)
                $payAmountTarget = [math]::Round($payAmount * (0.9 + $rand.NextDouble() * 0.2), 2)
                $newCustCntTarget = [math]::Max(1, [math]::Round($newCustCnt * (0.9 + $rand.NextDouble() * 0.2)))
                $newCustCostTarget = [math]::Round($newCustCost * (0.9 + $rand.NextDouble() * 0.2), 2)

                $row = [PSCustomObject]@{
                    dt                         = $currentDate.ToString("yyyy-MM-dd")
                    brand                      = $brand
                    framework                  = $fw
                    ads_format                 = $ads
                    impression                 = $impression
                    click                      = $click
                    cost                       = $cost
                    order_cnt                  = $orderCnt
                    pay_amount                 = $payAmount
                    new_customer_cnt           = $newCustCnt
                    new_customer_cost          = $newCustCost
                    new_customer_pay_amount    = $newCustPayAmount
                    cost_ly                    = $costLy
                    pay_amount_ly              = $payAmountLy
                    new_customer_cnt_ly        = $newCustCntLy
                    new_customer_cost_ly       = $newCustCostLy
                    new_customer_pay_amount_ly = $newCustPayAmountLy
                    cost_target                = $costTarget
                    pay_amount_target          = $payAmountTarget
                    new_customer_cnt_target    = $newCustCntTarget
                    new_customer_cost_target   = $newCustCostTarget
                }
                [void]$rows.Add($row)
            }
        }
    }
    $currentDate = $currentDate.AddDays(1)
}

$csvPath = Join-Path $OutputDir "KP_KPIs_sample.csv"
$rows | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8
Write-Host "KP_KPIs: $($rows.Count) rows => DONE"
