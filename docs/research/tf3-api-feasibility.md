# TF3-API: Machbarkeit von Line Insights v0.1

Stand: 03.10.2026. Untersuchung für [TF3-API und Mindestumfang für v0.1 verifizieren](https://github.com/teneris/tf3-line-insights/issues/2). Keine Laufzeitprüfung, keine Mod-Implementierung.

## Ergebnis und Quellenstand

TF3 ist öffentlich verfügbar: Urban Games meldet den Release am 29.09.2026. Die öffentliche Script-Referenz trägt den Generierungsstand 19.08.2026; eine konkrete Buildnummer fehlt. Dokumentation belegt Schnittstellen, aber keine Funktionsprüfung im laufenden Release. [Release](https://www.transportfever3.com/news/transport-fever-3-is-here/), [Referenzindex](https://wiki.transportfever3.com/script-doc/index.html).

Die Mindestanalyse ist dokumentationsseitig plausibel. Die Freigabe für v0.1 wartet auf lokale Nachweise für Zeitbasis, Haltindizes, Klassifikation und Auslösung. Abschnittsbelegung bleibt bis zur Prüfung unbekannt.

## Machbarkeitsmatrix

Alle TF3-Zeilen beziehen sich auf die oben datierte öffentliche Referenz. Die folgenden Funktionsnamen sind dokumentierte Kandidaten, kein ausführbarer Beispielcode.

| Bedarf | TF3-Nachweis | Grenze / TF2-Vergleich |
|---|---|---|
| Linien | `api.engine.system.lineSystem.getLines()` / `getLinesForPlayer(playerEntity)` liefern IDs. [System](https://wiki.transportfever3.com/script-doc/api/engine/system.html) | Keine fertige Personenlinien-Auswahl belegt; leere, gemischte und Güterlinien lokal unterscheiden. TF2 hat dieselben Linienabfragen. |
| Personen einer Linie | `simPersonSystem.getSimPersonsForLine(lineEntity)` liefert Personen-IDs. [System](https://wiki.transportfever3.com/script-doc/api/engine/system.html) | Wartend/unterwegs über Komponenten filtern; Mitgliedschaft bei Umstieg lokal prüfen. Auch in TF2 dokumentiert. |
| Wartende pro Halt | `simEntityAtTerminalSystem.getLineStopSimEntities(line, stopIndex, cargoType)` liefert IDs; `getLineStopSimEntitiesCount` die Anzahl. [System](https://wiki.transportfever3.com/script-doc/api/engine/system.html) | TF3-spezifisch belegter Kandidat für gezielte Abfragen; Beschreibung der Listenfunktion sagt irreführend „count“, Rückgabetyp und Returns sagen IDs. |
| Personen-Cargotyp | `api.res.cargoTypeRep.getPassengerCargoTypeId()` liefert die ID. [Res](https://wiki.transportfever3.com/script-doc/api/res.html) | Keine fest codierte 0 aus TF2 übernehmen. |
| Komponenten lesen | `api.engine.getComponent(entity, type)`, fehlend → nil; `api.engine.ComponentType`. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Die lokalen TF3-Typdefinitionen enthalten auch den Alias `api.type.ComponentType`; siehe [lokale Diagnose](tf3-local-diagnostic.md). Entity muss existieren. |
| Name/Halte | `NAME.name`, `LINE.stops`: geordnete Halte mit `stationGroup`, `station`, `terminal`. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Station/Terminal sind Unterindizes; wiederholte Halte getrennt halten. |
| Wartender Fahrtwunsch | `SIM_ENTITY_AT_TERMINAL`: `line`, `lineStop0`, `lineStop1`, `arrivalTime`, `vehicle`. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Einstieg, geplanter Ausstieg, Wartebeginn; Felder auch in TF2. Zeit-Einheit und Indexbasis offen. |
| Belegung | `SIM_ENTITY_AT_VEHICLE`: `line`, `vehicle`, `lineStop0/1`; Fahrzeug: `TRANSPORT_VEHICLE.stopIndex`. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Aktueller Abschnitt aus stopIndex allein noch nicht validiert; nicht alle geplanten Abschnitte als aktuelle Belegung zählen. |
| Fahrzeuganzahl Personen | `simEntityAtVehicleSystem.getVehicleSimEntitiesCountForCargoType(vehicle, cargoType)`. [System](https://wiki.transportfever3.com/script-doc/api/engine/system.html) | Plausibilitätsvergleich, kein Nachweis des aktuellen Abschnitts. |
| Messzeit | `GAME_TIME.gameTime/gameTime0`, `updateCount`, `tickCount`; `GAME_SPEED.millisPerDay`. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Kalender, Simulation und Terminalzeit nicht ungeprüft gleichsetzen. |
| Ausführung | Engine-Lesezugriff in GUI-/Engine-State. [Engine](https://wiki.transportfever3.com/script-doc/api/engine.html) | Konsistenz über mehrere Updates separat prüfen. |
| Manuell messen | `GameScript.handleEvent`, `update`, `postUpdate`; `GameScriptWithGui.guiHandleEvent`. [Gamescript](https://wiki.transportfever3.com/script-doc/content/scripts/gamescript.html) | Hooks bestätigt, konkrete Event-Auslösung/Registration und Einbindung in bestehenden Spielstand offen. |
| Log | `content.scripts.log`: `log.message(string)`, `warning`, `verbose`, `error`. [Log](https://wiki.transportfever3.com/script-doc/content/scripts/log.html) | Import, Ausgabeort und Sichtbarkeit lokal prüfen. |

Der TF3-Modding-Leitfaden kennzeichnet Game Scripts und User Interface noch als „Coming Soon“. Die Referenz benennt Hooks, ersetzt aber keine vollständige Anleitung. Ressourcenstruktur geändert: Game Scripts `.gs.lua`, Script-Ressourcen `.script.lua`/`.script.tl`; kein ungeprüftes TF2-Modgerüst verwenden. [Manual](https://wiki.transportfever3.com/doku.php?id=modding:start), [Ressourcen](https://wiki.transportfever3.com/doku.php?id=modding:general:resourcetypes).

TF2-Belege dienen ausschließlich zum Vergleich: [Engine](https://wiki.transportfever2.com/api/modules/api.engine.html), [Typen](https://wiki.transportfever2.com/api/modules/api.type.html). MoreLineStats wurde nicht als Beweis der TF3-Lauffähigkeit verwendet.

## Erforderliche lokale Nachweise vor Implementierungsfreigabe

Diese Prüfliste ist eine Untersuchungsempfehlung aus den offenen Bedeutungsfragen, kein behauptetes API-Verhalten.

1. Installierte Spielversion/Build dokumentieren; öffentliche Referenz mit lokalen Definitionen und Originalskripten abgleichen. Vorhandenen Spielstand für Versuche kopieren.
2. Manuelle Auslösung konkret belegen: geladenes Game Script, Registrierung, Event-Absender und Empfänger, Übergang GUI → Engine sowie vollständige Logausgabe. Kein TF2-`sendScriptEvent` übernehmen, dessen TF3-Signatur hier nicht bestätigt wurde.
3. Personenlinie zuverlässig klassifizieren: Linie ohne Fahrzeuge, momentan ohne Personen, Güterlinie und mögliche Mischkonfigurationen prüfen. Eine leere Personenliste ist kein Güterlinien-Nachweis.
4. Haltindizes aus Dumps mit UI vergleichen: einfache Linie, Ring einschließlich letztem → erstem Abschnitt und mehrfach besuchter Station. Stationsname/Entity genügt nicht als Identität einer Haltposition. Gleiches Ein-/Ausstiegsindexpaar nicht ohne Nachweis als Nullstrecke oder volle Runde interpretieren.
5. Eine beobachtete wartende Person verfolgen: Ankunft, Zeitfortschritt, Pause, Geschwindigkeitswechsel, Boarding und Ausstieg. Rohzeiten zuerst protokollieren; erst nach Nachweis kompatibler Einheiten Wartezeit berechnen. Negative/unbekannte Werte ausweisen, nicht glätten.
6. Personenlisten vergleichen: linienbezogene Abfrage, haltbezogene Liste und Count; Zustand vor/nach Umstieg. Wartende und Belegung getrennt zählen; unbekannte Komponenten oder ungültige Zuordnung mit Grund erfassen.
7. Fahrzeugabschnitt über Abfahrt, Fahrt, Ankunft und Laden verfolgen. Bedeutung von `stopIndex` und Richtung validieren. Erst dann aktuelle Fahrgäste einem gerichteten Abschnitt zuordnen. API-Felder für Ein-/Ausstieg belegen allein nur deren Fahrtabschnitt, nicht ihren momentanen Ort.
8. Größte Linie und vollständigen Scan messen: Laufzeit, Zahl Personen/Komponenten, UI-Ruckeln. Gezielt pro Linie/Halt abfragen; keine dokumentierte Laufzeitgarantie gefunden. Über Updates verteilte Messung mit Beginn/Ende kennzeichnen. Löschung, Linienänderung und Personenwechsel während des Scans erkennen; bei veränderter Haltfolge Ergebnis verwerfen oder explizit ungültig markieren.

## Konsequenz für die Spezifikation

Die API-Recherche kann abgeschlossen werden: öffentliche TF3-Nachweise liegen vor, TF2-Annahmen und verbleibende Laufzeitfragen sind getrennt. Eine baubare Spezifikation muss die lokale Verifikationsstufe und ihre Akzeptanzkriterien enthalten. Dokumentation allein rechtfertigt weder „zuverlässig verfügbar“ noch eine Unterstützung ungeprüfter Ring-/Mehrfachhaltfälle. Weitere Reiseketten, GUI und Auto Naming bleiben außerhalb dieser Untersuchung.
