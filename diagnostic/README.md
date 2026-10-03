# Lokale TF3-Diagnose

Untersuchungsartefakt für [Wayfinder: Lokale TF3-Diagnose](https://github.com/teneris/tf3-line-insights/issues/4). Keine fertige v0.1-Implementierung.

## Installation

Den Ordner `teneris_line_insights_diagnostic` in den lokalen TF3-Modordner kopieren. TF3 neu starten, eine Kopie des Spielstands auswählen und unter „Mods hinzufügen“ den Mod „Line Insights - Diagnose“ aktivieren.

Der Mod enthält TF3-Ressourcen (`mod.json`, `.gs.lua`, `.script.lua`). Beim Laden wird sein Game-Script automatisch eingebunden. Es protokolliert `READY` und wartet auf eine manuelle Messanforderung.

## Messung

In der TF3-Lua-Konsole im passenden Ausführungskontext:

```lua
api.cmd.sendCommand(api.cmd.makeScriptingSendEventCmd("LineInsights", "LineInsights", "Measure", {}))
```

Für eine einzelne Linie dieselbe Anforderung mit `{lineId = 1234}` senden und die ID durch eine tatsächlich existierende Linie ersetzen.

Pro Update wird eine Linie verarbeitet. Wartende, Personen im Fahrzeug und nicht zuordenbare Personen werden getrennt gezählt. Bis zu 20 Rohdatenbeispiele pro Linie, Fahrtwünsche nach rohen Ein-/Ausstiegsindizes, Haltlisten und Vergleichszählungen erscheinen in `local/crash_dump/stdout.txt` mit `[LineInsights]`.

Die Rohdatenprüfung interpretiert Zeitdifferenzen noch nicht als fertige Wartezeitkennzahl. Nullbasierte Haltindizes wurden im vorhandenen Spielstand bestätigt. Ungeprüfte Abschnittsbelegung und Linienart bleiben ausdrücklich unbekannt. Ergebnisse und Grenzen stehen in [der lokalen Diagnose](../docs/research/tf3-local-diagnostic.md).

Für eine begrenzte Zeitprobe `{lineId = 1234, monitorTicks = 300}` verwenden. Sie beobachtet höchstens 300 Ticks und bis zu fünf anfangs wartende Personen, protokolliert alle zehn Ticks und endet mit `PROBE_COMPLETE`. Mit geschlossener Konsole Pause sowie Geschwindigkeiten vergleichen. `cpuSeconds` ist eine einzelne `os.clock()`-Differenz einschließlich Diagnoseausgabe, kein Leistungsbudget.

## Grenzen

Eine geänderte Haltfolge während der Verarbeitung wird im Abschluss als `valid=false` markiert; solche Ergebnisse nicht als Kennzahlen verwenden. Die Diagnose verarbeitet eine komplette Linie pro Update und enthält noch keine Begrenzung der Personenanzahl pro Update. Diese Kosten sind vor einer Freigabe zu messen.

Der Mod ändert keine Linien oder Fahrzeuge. Er speichert ausschließlich seinen Diagnosezustand (Bereitschaft und Messwarteschlange) im Spielstand. Untersuchungen erfolgen auf einer separaten Spielstandkopie.
