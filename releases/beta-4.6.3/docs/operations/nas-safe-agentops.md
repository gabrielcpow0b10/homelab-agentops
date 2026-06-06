# NAS-Safe AgentOps Model

The HomeLab AgentOps layer treats the NAS as optional storage.

Automated monitoring avoids deep NAS scans. NAS-safe checks use lightweight mount-state checks only, avoiding `du`, deep `find`, recursive listing, or other operations that may wake disks unnecessarily.
