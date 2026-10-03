# Lokale TF3-Diagnose

Stand: 03.10.2026. Untersuchung für [Lokale TF3-Diagnose für den Mindestumfang durchführen](https://github.com/teneris/tf3-line-insights/issues/4). Der belegte Umfang und seine Grenzen stehen fest; die Produktfreigabe ist eine anschließende Entscheidung.

## Umgebung und Spielstand

- TF3 Windows 64 bit, Spiel-Build 40408, Steam-Build 25533170, Saveformat 604.
- Zu Beginn letzter gespeicherter Spielstand: `Neues Spiel.sav`, 03.10.2026 00:45:27 (Europe/Berlin).
- SHA256 des Originals: `7A0C6C6A8F789870FA1CE760E13D89F5C112CE4EC9DEE0BDD687F5A8FF162C6A`.
- Untersuchung ausschließlich auf der bytegleichen Kopie `LineInsights Diagnose 2026-10-03.sav` und ihrer Autosicherung vom 03.10.2026 12:49. Die Simulation wurde in der Kopie fortgesetzt. Original am 03.10.2026 erneut mit unverändertem Hash geprüft.

## Bereits beobachtet

Die lokale Mod-Erkennung und Einbindung funktionieren. Das Spiel erzeugte die GameScript-Entity aus `diagnostic.gs.lua` und führte das Update-Script aus:

```text
2026-10-03 10:29:10Z Creating entity for newly added GameScript teneris_line_insights_diagnostic_1::/diagnostic.gs
2026-10-03 10:29:16Z [LineInsights] READY event=LineInsights/Measure
2026-10-03 10:33:05Z Game is ready
```

Die Diagnose ist installiert und in der Spielstandkopie aktiviert. Der manuelle Event-Aufruf funktioniert in der über `^` geöffneten Konsole. Texteingabe und Mausklicks sind automatisierbar; Enter wurde vom Nutzer gedrückt, weil das Spiel automatisierte Tastendrücke nicht verarbeitet.

Am 03.10.2026 um 10:42:53–10:42:57 UTC wurden 19 Linien im pausierten Spiel vollständig verarbeitet: 19 gültige Ergebnisse, keine `ERROR`-Meldung. Ein zweiter Aufruf mit `{lineId=81576}` verarbeitete ausschließlich „Obertshausen SB 1“ um 10:44:32 UTC. Die Rohdaten stehen in [tf3-diagnostic-evidence.txt](tf3-diagnostic-evidence.txt).

### Zählungen und Haltindizes

Im ersten Scan summieren sich die Linienmitgliedschaften auf 175: 76 wartend, 68 im Fahrzeug und 31 nicht zugeordnet. Das ist keine Anzahl eindeutiger Personen über das gesamte Netz; Umstiege können Mitgliedschaften mehrerer Linien erzeugen.

Alle protokollierten Haltabfragen stimmten überein: Personenkomponenten, Terminal-ID-Liste und Terminal-Count. Beispielsweise liefert „Obertshausen SB 1“ für Rohindizes 0–4 die Wartezahlen `0,3,3,2,1`. Seine fünf Fahrzeuge liefern zusammen 24 Personen, genau wie die Personenkomponenten. Die Linienmitgliedschaft umfasst 52 Personen: 9 wartend, 24 onboard, 19 ohne passenden Terminal-/Fahrzeugzustand. Letztere sind keine Wartenden und dürfen nicht als Nachfrage addiert werden; ihre weiteren Zustände wurden noch nicht untersucht.

Die Haltfolge dieser Linie ist Kastanienweg, Beethovenstrasse, Raiffeisenstrasse, Fliederweg, Kirchplatz. Die Linienansicht bestätigte exakt diese Reihenfolge als Positionen 1–5, das Personensymbol und fünf Straßenfahrzeuge. Wartende Fahrtwünsche `3->0` und `4->0` wurden beobachtet. Die Komponenten und Terminalabfragen verwenden nullbasierte Haltindizes, während `ipairs(line.stops)` bei 1 beginnt. Die Fahrt über das Ende der Folge ist als Rohdatum vorhanden. Eine vollständige Ring-/Abschnittsinterpretation wurde nicht geprüft. Im Scan wurde keine wiederholte Stationsgruppe innerhalb einer Haltfolge gefunden; Unterstützung wiederholter Haltpositionen bleibt ungeprüft.

### Pause und Zeit

Zwischen den beiden pausierten Messungen blieb `gameTime=25111400`, `gameTime0=25111400`, `updateCount=125557` unverändert; `tickCount` stieg von 162466 auf 162957. Wartebeginn und Zählungen blieben gleich. Beispiel Person 104762: `arrivalTime=25104400`, Differenz 7000 Rohzeiteinheiten in beiden Messungen. Das bestätigt die Pauseigenschaft, noch keine Einheit.

`millisPerDay=4000` blieb trotz `speedup=0` ungleich null. Deshalb dieses Feld nicht als alleinige Pauseerkennung verwenden. Die lokale Typbeschreibung und das beobachtete Verhalten weichen hier voneinander ab.

Die begrenzte Zeitprobe nach Neustart lief von 11:01:41 bis 11:02:28 UTC ohne Fehler und endete mit `PROBE_COMPLETE`. Rohbelege: [tf3-time-probe-evidence.txt](tf3-time-probe-evidence.txt). Bei Pause war `dt=0`; Wartebeginn und Spielzeit blieben unverändert. Bei `speedup=1` und `dt≈0.2` stieg `gameTime` in zwei Sekunden jeweils um 2000, bei `speedup=4` um 16000 zwischen 11:02:24 und 11:02:28. Pro Simulationsupdate stieg es weiterhin um 200. Damit ist die Interpretation als Simulationsmillisekunden empirisch gestützt. Die Wartezeitbasis lautet `(gameTime-arrivalTime)/1000` in Simulationssekunden, nur für einen weiterhin passenden Terminalzustand. Kalenderdauer und reale Zeit sind davon zu unterscheiden. `gameTime0` kann bei schneller Simulation hinter dem aktuellen Wert liegen; für den Messzeitpunkt `gameTime` verwenden.

### Wechsel vom Warten ins Fahrzeug

Eine Folgeabfrage um 10:50:07 UTC bestätigte bei zwei Personen den Zustandswechsel: Person 104762 und Person 115416 hatten zuvor einen passenden Terminalzustand auf Linie 81576. Danach war die Terminalkomponente nicht mehr vorhanden und die Fahrzeugkomponente verwies auf dieselbe Linie, mit Fahrzeug 81479 bzw. 80974. Damit ist die Trennung von wartend und onboard auch über einen tatsächlichen Einstieg hinweg beobachtet. Bei drei weiteren Personen war weder Terminal- noch Fahrzeugzustand vorhanden; daraus wird kein Einstieg abgeleitet.

### Klassifikation und Scan-Kosten

Linien ohne beobachtete Personen bleiben `unknown`, einschließlich einer Linie mit einem Halt und keinem Fahrzeug. Namen sind kein Beweis für die Transportart: „Benzin -> Obertshausen“ enthält beispielsweise drei Personen im Fahrzeug. Eine zuverlässige Unterscheidung von Personen-/Güter-/gemischten Linien ist noch offen.

Der Scan lief über 19 aufeinanderfolgende Simulations-Ticks in etwa vier Sekunden, eine Linie je Tick. Diese Gesamtdauer misst weder CPU-Kosten einer Linie noch die Skalierung bei großen Personenlisten. Die größte beobachtete Mitgliedschaft hat 57 Personen. Ein Lasttest großer Linien fehlt.

Die erweiterte Diagnose meldete für Linie 81576 mit 39 Personen `cpuSeconds≈0.002` über `os.clock()`. Das ist eine einzelne Messung einschließlich Diagnoseausgabe und kein belastbares Leistungsbudget. Große Listen und deren Einfluss auf Bildrate/Simulationslatenz sind mit diesem Spielstand nicht nachgewiesen. Vor einer allgemeinen Freigabe ist ein Lastfall oder eine Begrenzung der Arbeit pro Update erforderlich. Die Signaturprüfung der Haltfolge ist implementiert, aber ein absichtlich veränderter Linienverlauf wurde nicht getestet.

## Korrektur zur API-Recherche

Die mit dem installierten Spiel ausgelieferten Typdefinitionen beschreiben den Engine-Typ und den Alias `api.type.ComponentType` (`api/tealdef/api/type.d.tl`, Zeile 3758). Auch Basisskripte verwenden den Alias. **Zur Laufzeit wählte die Diagnose bei allen Linien den Fallback `api.type.ComponentType`**, weil `api.engine.ComponentType` dort nicht verfügbar war. Für Build 40408 ist der Handoff-Namespace somit korrekt; die öffentliche Referenz allein war keine verlässliche Namespace-Anleitung.

## Noch zu prüfen

| Nachweis | Status |
|---|---|
| Mod-Erkennung, GameScript, Update | Im Spiel bestätigt |
| Manueller Event-Aufruf für alle/eine Linie | Im Spiel bestätigt |
| Halteindizes, Warte-/Fahrzeugzählungen und OD | Nullbasierte Rohindizes und Vergleichszählungen bestätigt; Haltfolge der ausgewählten Personenlinie in der UI bestätigt |
| Zeitbasis, Pause, Geschwindigkeit, Boarding | Simulationsmillisekunden empirisch gestützt; Pause, 1x/4x und zwei Boarding-Wechsel bestätigt |
| Linienklassifikation einschließlich leerer Linien | Personenverwendung beobachtbar; leere und weitere Linienarten ohne verlässlichen Nachweis ausdrücklich unbekannt |
| Ringlinien / wiederholte Haltpositionen | OD über das Ende der Folge beobachtet; vollständige Ringinterpretation und wiederholte Haltpositionen ungeprüft |
| Abschnittsbelegung | Unbekannt |
| Kosten einer vollständigen Linienabfrage | Ein kleiner Fall ≈2 ms nach os.clock; große Scans und Haltänderungstest ungeprüft |

Ungeprüfte Felder dürfen nicht als fertige Kennzahlen oder bestätigte Unterstützung in die Spezifikation übernommen werden.

Zum Abschluss wurde TF3 regulär geschlossen und `debugMode` auf den ursprünglichen Wert `false` zurückgesetzt. Die vorgesehene Konsolentaste bleibt `^` (Scancode 53); F8 wurde nicht umbelegt. Die Diagnose-Moddateien und die separate Spielstandkopie bleiben für Wiederholungen erhalten.
