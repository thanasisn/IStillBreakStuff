
# hosts


An automated bash script I use to create hosts list for my linux machines.
I use it as crontab command.

- Already includes some lists in the configuration files.
- Download and merges lists from different sources.
- Accepts custom url entries.
- **Will try to update the host file.**
- It can list more than 815k domains.

It uses `sudo` to update the `/etc/hosts` file without any warning.
*May disrupt the spacetime continuum forever.*

I was inspired from [StevenBlack/hosts](https://github.com/StevenBlack/hosts) and revised a very very old script I had, for the similar purpose.
Here is my new version.


*Suggestions and improvements are always welcome.*

*I use those regular, but they have their quirks, may broke and maybe superseded by other tools.*
