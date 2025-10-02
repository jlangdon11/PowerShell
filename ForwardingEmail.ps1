# https://learn.microsoft.com/en-us/powershell/module/exchange/set-mailbox?view=exchange-ps

# Turns on forwarding for a specifed mailbox to another email and does not deliever emails to mailbox that is being forwarded

Set-Mailbox -Identity "" -ForwardingAddress "" -DeliverToMailboxAndForward $false # can use Name(Display Name), Alias, or Email address