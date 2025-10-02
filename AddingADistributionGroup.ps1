New-DistributionGroup -Name Test -Alias "test"

New-DistributionGroup -Name "Test2 - Factorylink" -PrimarySmtpAddress "test2@factorylink.com" -Members -ManagedBy jlangdon@factorylink.com, jnourse@factorylink.com -MemberJoinRestriction Closed -MemberDepartRestriction Closed -RequireSenderAuthenticationEnabled $false