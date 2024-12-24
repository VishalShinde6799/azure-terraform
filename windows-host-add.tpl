add-content -path C:/Users/vshinde/.ssh/config -value @'

Host ${hostname}
    Hostname ${hostname}
    User ${username}
    identityFile ${identityfile}
'@