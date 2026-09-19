import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case en, es, fr, de, it, pt, pl, ru, uk
    var id: String { rawValue }
    var name: String {
        switch self { case .ru: return "Русский"; case .uk: return "Українська"; case .en: return "English"; case .es: return "Español"; case .fr: return "Français"; case .de: return "Deutsch"; case .it: return "Italiano"; case .pt: return "Português"; case .pl: return "Polski" }
    }
    var speechLocale: String {
        switch self { case .ru: return "ru-RU"; case .uk: return "uk-UA"; case .en: return "en-US"; case .es: return "es-ES"; case .fr: return "fr-FR"; case .de: return "de-DE"; case .it: return "it-IT"; case .pt: return "pt-BR"; case .pl: return "pl-PL" }
    }
    var translationIndex: Int? {
        [.uk, .en, .es, .fr, .de, .it, .pt, .pl].firstIndex(of: self)
    }
    static var current: AppLanguage {
        AppLanguage(rawValue: UserDefaults.standard.string(forKey: "blindchess.language") ?? "ru") ?? .ru
    }
}

// Russian source keys remain stable; values: uk, en, es, fr, de, it, pt, pl.
enum AppStrings {
    static let translations: [String: [String]] = [
        "Выбрать язык": ["Вибрати мову", "Choose language", "Elegir idioma", "Choisir la langue", "Sprache wählen", "Scegli lingua", "Escolher idioma", "Wybierz język"],
        "Здесь ход компьютера": ["Тут хід комп’ютера", "Computer’s turn here", "Aquí juega el ordenador", "Au tour de l’ordinateur ici", "Hier ist der Computer am Zug", "Qui tocca al computer", "Aqui é a vez do computador", "Tutaj ruch komputera"],
        "Новый ход заменит последующие": ["Новий хід замінить наступні", "A new move replaces later moves", "Una nueva jugada sustituye las siguientes", "Un nouveau coup remplace les suivants", "Ein neuer Zug ersetzt spätere Züge", "Una nuova mossa sostituisce le successive", "Um novo lance substitui os seguintes", "Nowy ruch zastąpi kolejne"],
        "Перейдите к позиции с вашим ходом": ["Перейдіть до позиції з вашим ходом", "Go to a position where it’s your turn", "Ve a una posición donde te toque jugar", "Revenez à une position où c’est votre tour", "Gehe zu einer Position, in der du am Zug bist", "Vai a una posizione in cui tocca a te", "Vá para uma posição em que seja sua vez", "Przejdź do pozycji, w której jest twój ruch"],
        "Подготовка словаря": ["Підготовка словника", "Preparing vocabulary", "Preparando vocabulario", "Préparation du vocabulaire", "Wortschatz wird vorbereitet", "Preparazione del vocabolario", "Preparando vocabulário", "Przygotowywanie słownika"],
        "Подготовка обработки голоса": ["Підготовка обробки голосу", "Preparing voice processing", "Preparando el procesamiento de voz", "Préparation du traitement vocal", "Sprachverarbeitung wird vorbereitet", "Preparazione dell’elaborazione vocale", "Preparando processamento de voz", "Przygotowywanie przetwarzania mowy"],
        "Загрузка распознавания": ["Завантаження розпізнавання", "Loading recognition", "Cargando reconocimiento", "Chargement de la reconnaissance", "Spracherkennung wird geladen", "Caricamento del riconoscimento", "Carregando reconhecimento", "Ładowanie rozpoznawania"],
        "Подготовка звука": ["Підготовка звуку", "Preparing audio", "Preparando audio", "Préparation audio", "Audio wird vorbereitet", "Preparazione audio", "Preparando áudio", "Przygotowywanie dźwięku"],
        "Этап {0} из 4 · {1}": ["Етап {0} із 4 · {1}", "Step {0} of 4 · {1}", "Paso {0} de 4 · {1}", "Étape {0} sur 4 · {1}", "Schritt {0} von 4 · {1}", "Passaggio {0} di 4 · {1}", "Etapa {0} de 4 · {1}", "Etap {0} z 4 · {1}"],
        "Проверяем модель…": ["Перевіряємо модель…", "Checking model…", "Comprobando el modelo…", "Vérification du modèle…", "Modell wird geprüft…", "Verifica del modello…", "Verificando o modelo…", "Sprawdzanie modelu…"],
        "Не удалось сохранить изменения архива. Попробуйте снова.": ["Не вдалося зберегти зміни архіву. Спробуйте знову.", "Could not save archive changes. Try again.", "No se pudieron guardar los cambios del archivo. Inténtalo de nuevo.", "Impossible d’enregistrer les modifications des archives. Réessayez.", "Änderungen am Archiv konnten nicht gespeichert werden. Versuche es erneut.", "Impossibile salvare le modifiche all’archivio. Riprova.", "Não foi possível salvar as alterações do arquivo. Tente novamente.", "Nie udało się zapisać zmian w archiwum. Spróbuj ponownie."],
        "Не удалось открыть архив. Сохранённый файл не изменён.": ["Не вдалося відкрити архів. Збережений файл не змінено.", "Could not open the archive. The saved file was not changed.", "No se pudo abrir el archivo. El fichero guardado no se ha modificado.", "Impossible d’ouvrir les archives. Le fichier enregistré n’a pas été modifié.", "Archiv konnte nicht geöffnet werden. Die gespeicherte Datei wurde nicht verändert.", "Impossibile aprire l’archivio. Il file salvato non è stato modificato.", "Não foi possível abrir o arquivo. O arquivo salvo não foi alterado.", "Nie udało się otworzyć archiwum. Zapisany plik nie został zmieniony."],
        "К концу партии": ["До кінця партії", "Go to end", "Ir al final", "Aller à la fin", "Zum Ende", "Vai alla fine", "Ir ao fim", "Na koniec"],
        "К началу партии": ["До початку партії", "Go to start", "Ir al inicio", "Aller au début", "Zum Anfang", "Vai all’inizio", "Ir ao início", "Na początek"],
        "Начальная позиция": ["Початкова позиція", "Starting position", "Posición inicial", "Position initiale", "Ausgangsstellung", "Posizione iniziale", "Posição inicial", "Pozycja początkowa"],
        "Все записи архива будут удалены. Текущая игра продолжится.": ["Усі записи архіву будуть видалені. Поточна гра продовжиться.", "All archive entries will be deleted. Your current game will continue.", "Se eliminarán todas las partidas del archivo. La partida actual continuará.", "Toutes les parties archivées seront supprimées. La partie en cours continuera.", "Alle archivierten Partien werden gelöscht. Deine aktuelle Partie läuft weiter.", "Tutte le partite archiviate saranno eliminate. La partita attuale continuerà.", "Todas as partidas arquivadas serão excluídas. A partida atual continuará.", "Wszystkie partie z archiwum zostaną usunięte. Bieżąca gra będzie kontynuowana."],
        "Удалить все партии": ["Видалити всі партії", "Delete all games", "Eliminar todas las partidas", "Supprimer toutes les parties", "Alle Partien löschen", "Elimina tutte le partite", "Excluir todas as partidas", "Usuń wszystkie partie"],
        "Очистить весь архив?": ["Очистити весь архів?", "Clear the entire archive?", "¿Vaciar todo el archivo?", "Vider toutes les archives ?", "Gesamtes Archiv leeren?", "Svuotare tutto l’archivio?", "Limpar todo o arquivo?", "Wyczyścić całe archiwum?"],
        "Запись исчезнет из архива. Текущая игра продолжится.": ["Запис зникне з архіву. Поточна гра продовжиться.", "The entry will be removed from the archive. Your current game will continue.", "La partida se eliminará del archivo. La partida actual continuará.", "La partie sera retirée des archives. La partie en cours continuera.", "Die Partie wird aus dem Archiv entfernt. Deine aktuelle Partie läuft weiter.", "La partita sarà rimossa dall’archivio. La partita attuale continuerà.", "A partida será removida do arquivo. A partida atual continuará.", "Partia zostanie usunięta z archiwum. Bieżąca gra będzie kontynuowana."],
        "Удалить партию?": ["Видалити партію?", "Delete this game?", "¿Eliminar esta partida?", "Supprimer cette partie ?", "Diese Partie löschen?", "Eliminare questa partita?", "Excluir esta partida?", "Usunąć tę partię?"],
        "Очистить": ["Очистити", "Clear", "Vaciar", "Vider", "Leeren", "Svuota", "Limpar", "Wyczyść"],
        "Удалить": ["Видалити", "Delete", "Eliminar", "Supprimer", "Löschen", "Elimina", "Excluir", "Usuń"],
        "{0} · сила {1} · ходов: {2}": ["{0} · сила {1} · ходів: {2}", "{0} · strength {1} · moves: {2}", "{0} · nivel {1} · jugadas: {2}", "{0} · niveau {1} · coups : {2}", "{0} · Stärke {1} · Züge: {2}", "{0} · livello {1} · mosse: {2}", "{0} · nível {1} · lances: {2}", "{0} · poziom {1} · ruchy: {2}"],
        "Ничья": ["Нічия", "Draw", "Tablas", "Nulle", "Remis", "Patta", "Empate", "Remis"],
        "Не завершена": ["Не завершена", "Unfinished", "Sin terminar", "Inachevée", "Nicht beendet", "Incompleta", "Inacabada", "Niedokończona"],
        "Поражение": ["Поразка", "Loss", "Derrota", "Défaite", "Niederlage", "Sconfitta", "Derrota", "Porażka"],
        "Победа": ["Перемога", "Win", "Victoria", "Victoire", "Sieg", "Vittoria", "Vitória", "Wygrana"],
        "Начатые партии сохраняются здесь автоматически.": ["Розпочаті партії зберігаються тут автоматично.", "Games are saved here automatically once play begins.", "Las partidas se guardan aquí automáticamente al empezar a jugar.", "Les parties sont enregistrées ici automatiquement dès le début du jeu.", "Partien werden hier nach Spielbeginn automatisch gespeichert.", "Le partite vengono salvate qui automaticamente quando inizi a giocare.", "As partidas são salvas aqui automaticamente quando o jogo começa.", "Rozpoczęte partie są tu zapisywane automatycznie."],
        "Архив пока пуст": ["Архів поки порожній", "No archived games yet", "Aún no hay partidas archivadas", "Aucune partie archivée", "Noch keine archivierten Partien", "Nessuna partita archiviata", "Nenhuma partida arquivada", "Brak zapisanych partii"],
        "Архив партий": ["Архів партій", "Game archive", "Archivo de partidas", "Archives des parties", "Partienarchiv", "Archivio partite", "Arquivo de partidas", "Archiwum partii"],
        "Продвинутый игрок": ["Просунутий гравець", "Advanced player", "Jugador avanzado", "Joueur avancé", "Fortgeschrittener Spieler", "Giocatore avanzato", "Jogador avançado", "Zaawansowany gracz"],
        "Гроссмейстер": ["Гросмейстер", "Grandmaster", "Gran maestro", "Grand maître", "Großmeister", "Grande maestro", "Grande mestre", "Arcymistrz"],
        "Элитный гроссмейстер": ["Елітний гросмейстер", "Elite grandmaster", "Gran maestro de élite", "Grand maître d’élite", "Elite-Großmeister", "Grande maestro d’élite", "Grande mestre de elite", "Elitarny arcymistrz"],
        "Магнус Карлсен": ["Магнус Карлсен", "Magnus Carlsen", "Magnus Carlsen", "Magnus Carlsen", "Magnus Carlsen", "Magnus Carlsen", "Magnus Carlsen", "Magnus Carlsen"],
        "Первые шаги": ["Перші кроки", "First steps", "Primeros pasos", "Premiers pas", "Erste Schritte", "Primi passi", "Primeiros passos", "Pierwsze kroki"],
        "Начинающий игрок": ["Гравець-початківець", "Beginner", "Principiante", "Débutant", "Anfänger", "Principiante", "Iniciante", "Początkujący"],
        "Уверенный любитель": ["Впевнений аматор", "Confident amateur", "Aficionado seguro", "Amateur confirmé", "Sicherer Amateur", "Dilettante sicuro", "Amador confiante", "Pewny siebie amator"],
        "Опытный соперник": ["Досвідчений суперник", "Experienced opponent", "Rival experimentado", "Adversaire expérimenté", "Erfahrener Gegner", "Avversario esperto", "Adversário experiente", "Doświadczony przeciwnik"],
        "Мастерский уровень": ["Майстерний рівень", "Master-level play", "Nivel de maestro", "Niveau maître", "Meisterniveau", "Livello maestro", "Nível de mestre", "Poziom mistrzowski"],
        "Очень сильный соперник": ["Дуже сильний суперник", "Very strong opponent", "Rival muy fuerte", "Adversaire très fort", "Sehr starker Gegner", "Avversario molto forte", "Adversário muito forte", "Bardzo silny przeciwnik"],
        "Уровень игры компьютера": ["Рівень гри комп’ютера", "Computer skill level", "Nivel del ordenador", "Niveau de l’ordinateur", "Spielstärke des Computers", "Livello del computer", "Nível do computador", "Poziom gry komputera"],
        "Уменьшить силу": ["Зменшити силу", "Decrease strength", "Reducir nivel", "Réduire le niveau", "Spielstärke verringern", "Riduci il livello", "Diminuir nível", "Zmniejsz poziom"],
        "Увеличить силу": ["Збільшити силу", "Increase strength", "Aumentar nivel", "Augmenter le niveau", "Spielstärke erhöhen", "Aumenta il livello", "Aumentar nível", "Zwiększ poziom"],
        "Включаю микрофон…": ["Вмикаю мікрофон…", "Starting microphone…", "Activando micrófono…", "Activation du microphone…", "Mikrofon wird aktiviert…", "Attivazione del microfono…", "Ativando microfone…", "Włączanie mikrofonu…"],
        "Нажмите, чтобы включить голос": ["Натисніть, щоб увімкнути голос", "Tap to enable voice", "Toca para activar la voz", "Touchez pour activer la voix", "Tippen, um Sprache zu aktivieren", "Tocca per attivare la voce", "Toque para ativar a voz", "Dotknij, aby włączyć głos"],
        "Микрофон пока выключен": ["Мікрофон поки вимкнений", "Microphone is off for now", "Micrófono desactivado por ahora", "Microphone désactivé pour le moment", "Mikrofon derzeit aus", "Microfono al momento disattivato", "Microfone desativado por enquanto", "Mikrofon jest na razie wyłączony"],
        "Подготовка занимает больше времени, чем обычно.": ["Підготовка триває довше, ніж зазвичай.", "Preparation is taking longer than usual.", "La preparación está tardando más de lo habitual.", "La préparation prend plus de temps que d’habitude.", "Die Vorbereitung dauert länger als üblich.", "La preparazione richiede più tempo del solito.", "A preparação está demorando mais que o normal.", "Przygotowanie trwa dłużej niż zwykle."],
        "Повторить подготовку": ["Повторити підготовку", "Retry preparation", "Reintentar preparación", "Relancer la préparation", "Vorbereitung wiederholen", "Riprova la preparazione", "Repetir preparação", "Ponów przygotowanie"],
        "Похоже, вы сказали «Отмена».": ["Здається, ви сказали «Скасувати».", "It sounds like you said “Undo”.", "Parece que has dicho «Deshacer».", "Il semble que vous ayez dit «Annuler».", "Du hast wohl „Zurücknehmen“ gesagt.", "Sembra che tu abbia detto «Annulla».", "Parece que você disse “Desfazer”.", "Chyba padło słowo „Cofnij”."],
        "Нет ходов для отмены": ["Немає ходів для скасування", "No moves to undo", "No hay jugadas que deshacer", "Aucun coup à annuler", "Keine Züge zum Zurücknehmen", "Nessuna mossa da annullare", "Nenhum lance para desfazer", "Brak ruchów do cofnięcia"],
        "Какой фигурой на {0}?": ["Якою фігурою на {0}?", "Which piece to {0}?", "¿Qué pieza a {0}?", "Quelle pièce en {0} ?", "Welche Figur nach {0}?", "Quale pezzo in {0}?", "Qual peça para {0}?", "Która figura na {0}?"],
        "С какой клетки на {0}?": ["З якої клітинки на {0}?", "From which square to {0}?", "¿Desde qué casilla a {0}?", "De quelle case vers {0} ?", "Von welchem Feld nach {0}?", "Da quale casa a {0}?", "De qual casa para {0}?", "Z którego pola na {0}?"],
        "Не уверен, какая клетка названа. Повторите конечную клетку.": ["Не впевнений, яку клітинку названо. Повторіть кінцеву клітинку.", "I'm not sure which square you named. Repeat the destination square.", "No sé qué casilla has dicho. Repite la casilla de destino.", "La case indiquée n’est pas claire. Répétez la case d’arrivée.", "Das genannte Feld ist unklar. Wiederhole das Zielfeld.", "Non è chiara la casa indicata. Ripeti la casa di arrivo.", "Não ficou claro qual casa foi dita. Repita a casa de destino.", "Nie mam pewności, jakie pole padło. Powtórz pole docelowe."],
        "Подтвердите ход": ["Підтвердьте хід", "Confirm move", "Confirmar jugada", "Confirmer le coup", "Zug bestätigen", "Conferma mossa", "Confirmar lance", "Potwierdź ruch"],
        "Сделать ход": ["Зробити хід", "Play move", "Jugar", "Jouer le coup", "Zug ausführen", "Esegui mossa", "Jogar lance", "Wykonaj ruch"],
        "Повторить команду": ["Повторити команду", "Try again", "Intentar de nuevo", "Réessayer", "Erneut versuchen", "Riprova", "Tentar novamente", "Spróbuj ponownie"],
        "Вы имели в виду: {0}?": ["Ви мали на увазі: {0}?", "Did you mean: {0}?", "¿Querías decir: {0}?", "Vouliez-vous dire : {0} ?", "Meintest du: {0}?", "Intendevi: {0}?", "Você quis dizer: {0}?", "Czy chodziło o: {0}?"],
        "Последняя клетка — куда идёт фигура. Можно назвать обе: «е два — е четыре».": ["Остання клітинка — куди йде фігура. Можна назвати обидві: «е два — е чотири».", "The last square is the destination. You can name both: “e two — e four”.", "La última casilla es el destino. Puedes decir ambas: «e dos — e cuatro».", "La dernière case est l’arrivée. Vous pouvez dire les deux : «e deux — e quatre».", "Das letzte Feld ist das Ziel. Du kannst beide nennen: „e zwei — e vier“.", "L’ultima casa è la destinazione. Puoi dirle entrambe: «e due — e quattro».", "A última casa é o destino. Você pode dizer ambas: “e dois — e quatro”.", "Ostatnie pole to cel ruchu. Możesz podać oba: „e dwa — e cztery”."],
        "Вы проиграли :(": ["Ви програли :(", "You lost :(", "Has perdido :(", "Vous avez perdu :(", "Du hast verloren :(", "Hai perso :(", "Você perdeu :(", "Przegrana :("],
        "Вы выиграли": ["Ви виграли", "You won", "Has ganado", "Vous avez gagné", "Du hast gewonnen", "Hai vinto", "Você venceu", "Wygrana"],
        "Вы победили!": ["Ви перемогли!", "You won!", "¡Has ganado!", "Vous avez gagné !", "Du hast gewonnen!", "Hai vinto!", "Você venceu!", "Wygrana!"],
        "Загрузка голосовой модели": ["Завантаження голосової моделі", "Downloading voice model", "Descargando modelo de voz", "Téléchargement du modèle vocal", "Sprachmodell wird heruntergeladen", "Download del modello vocale", "Baixando modelo de voz", "Pobieranie modelu mowy"],
        "Скачиваем модель на телефон, чтобы распознавать голос без интернета.": ["Завантажуємо модель на телефон, щоб розпізнавати голос без інтернету.", "Downloading a model to your phone to recognize speech offline.", "Descargamos un modelo en el teléfono para reconocer la voz sin internet.", "Téléchargement d’un modèle sur le téléphone pour reconnaître la parole hors ligne.", "Ein Modell wird auf dein Telefon geladen, um Sprache ohne Internet zu erkennen.", "Scarichiamo un modello sul telefono per riconoscere la voce senza internet.", "Baixando um modelo no telefone para reconhecer a voz sem internet.", "Pobieramy model na telefon, aby rozpoznawać mowę bez internetu."],
        "Новая партия": ["Нова партія", "New game", "Nueva partida", "Nouvelle partie", "Neue Partie", "Nuova partita", "Nova partida", "Nowa partia"],
        "Ввести ход": ["Ввести хід", "Enter move", "Introducir jugada", "Saisir un coup", "Zug eingeben", "Inserisci mossa", "Inserir lance", "Wpisz ruch"],
        "Отменить ход": ["Скасувати хід", "Undo move", "Deshacer jugada", "Annuler le coup", "Zug zurücknehmen", "Annulla mossa", "Desfazer lance", "Cofnij ruch"],
        "Готовлю журнал…": ["Готую журнал…", "Preparing log…", "Preparando registro…", "Préparation du journal…", "Protokoll wird vorbereitet…", "Preparazione del registro…", "Preparando registro…", "Przygotowywanie dziennika…"],
        "Выгрузить журнал": ["Експортувати журнал", "Export log", "Exportar registro", "Exporter le journal", "Protokoll exportieren", "Esporta registro", "Exportar registro", "Eksportuj dziennik"],
        "Меню партии": ["Меню партії", "Game menu", "Menú de partida", "Menu de la partie", "Partiemenü", "Menu partita", "Menu da partida", "Menu partii"],
        "Вид игры": ["Режим гри", "Game view", "Vista de juego", "Vue du jeu", "Spielansicht", "Vista di gioco", "Visualização do jogo", "Widok gry"],
        "Вслепую": ["Наосліп", "Blindfold", "A ciegas", "À l’aveugle", "Blindspiel", "Alla cieca", "Às cegas", "Na ślepo"],
        "Доска": ["Дошка", "Board", "Tablero", "Échiquier", "Brett", "Scacchiera", "Tabuleiro", "Szachownica"],
        "На ход назад": ["На хід назад", "Previous move", "Jugada anterior", "Coup précédent", "Vorheriger Zug", "Mossa precedente", "Lance anterior", "Poprzedni ruch"],
        "На ход вперёд": ["На хід уперед", "Next move", "Jugada siguiente", "Coup suivant", "Nächster Zug", "Mossa successiva", "Próximo lance", "Następny ruch"],
        "{0}% · около 220 МБ, один раз": ["{0}% · близько 220 МБ, одноразово", "{0}% · about 220 MB, once", "{0}% · unos 220 MB, una sola vez", "{0}% · environ 220 Mo, une seule fois", "{0}% · etwa 220 MB, einmalig", "{0}% · circa 220 MB, una sola volta", "{0}% · cerca de 220 MB, uma vez", "{0}% · około 220 MB, jednorazowo"],
        "Шах": ["Шах", "Check", "Jaque", "Échec", "Schach", "Scacco", "Xeque", "Szach"],
        "К текущей позиции": ["До поточної позиції", "Current position", "Posición actual", "Position actuelle", "Aktuelle Stellung", "Posizione attuale", "Posição atual", "Bieżąca pozycja"],
        "Удерживайте, чтобы говорить": ["Утримуйте, щоб говорити", "Hold to speak", "Mantén pulsado para hablar", "Maintenez pour parler", "Zum Sprechen gedrückt halten", "Tieni premuto per parlare", "Segure para falar", "Przytrzymaj, aby mówić"],
        "Вернуться к игре": ["Повернутися до гри", "Return to game", "Volver a la partida", "Revenir à la partie", "Zur Partie zurück", "Torna alla partita", "Voltar à partida", "Wróć do gry"],
        "Отпустите, чтобы отправить ход. С VoiceOver: двойное касание начинает или завершает запись.": ["Відпустіть, щоб надіслати хід. З VoiceOver: подвійний дотик починає або завершує запис.", "Release to send your move. With VoiceOver, double-tap to start or stop recording.", "Suelta para enviar la jugada. Con VoiceOver, toca dos veces para iniciar o detener la grabación.", "Relâchez pour envoyer le coup. Avec VoiceOver, touchez deux fois pour démarrer ou arrêter l’enregistrement.", "Loslassen, um den Zug zu senden. Mit VoiceOver startet oder beendet Doppeltippen die Aufnahme.", "Rilascia per inviare la mossa. Con VoiceOver, tocca due volte per avviare o fermare la registrazione.", "Solte para enviar o lance. Com VoiceOver, toque duas vezes para iniciar ou parar a gravação.", "Puść, aby wysłać ruch. Z VoiceOver stuknij dwukrotnie, aby rozpocząć lub zakończyć nagrywanie."],
        "Отмена": ["Скасувати", "Cancel", "Cancelar", "Annuler", "Abbrechen", "Annulla", "Cancelar", "Anuluj"],
        "Ошибка движка": ["Помилка рушія", "Engine error", "Error del motor", "Erreur du moteur", "Engine-Fehler", "Errore del motore", "Erro do motor", "Błąd silnika"],
        "Повторить": ["Повторити", "Retry", "Reintentar", "Réessayer", "Wiederholen", "Riprova", "Repetir", "Ponów"],
        "Закрыть": ["Закрити", "Close", "Cerrar", "Fermer", "Schließen", "Chiudi", "Fechar", "Zamknij"],
        "Попробуйте снова.": ["Спробуйте ще раз.", "Please try again.", "Inténtalo de nuevo.", "Veuillez réessayer.", "Versuche es erneut.", "Riprova.", "Tente novamente.", "Spróbuj ponownie."],
        "Не удалось выгрузить журнал": ["Не вдалося експортувати журнал", "Could not export log", "No se pudo exportar el registro", "Impossible d’exporter le journal", "Protokoll konnte nicht exportiert werden", "Impossibile esportare il registro", "Não foi possível exportar o registro", "Nie udało się wyeksportować dziennika"],
        "Отменить последний ход?": ["Скасувати останній хід?", "Undo last move?", "¿Deshacer la última jugada?", "Annuler le dernier coup ?", "Letzten Zug zurücknehmen?", "Annullare l’ultima mossa?", "Desfazer o último lance?", "Cofnąć ostatni ruch?"],
        "Не отменять": ["Не скасовувати", "Keep move", "Conservar jugada", "Conserver le coup", "Zug behalten", "Mantieni mossa", "Manter lance", "Zachowaj ruch"],
        "Вернёмся к вашему предыдущему ходу. Ответ компьютера, если он уже сделан, тоже будет отменён.": ["Повернемося до вашого попереднього ходу. Відповідь комп’ютера, якщо вона вже є, теж буде скасована.", "Your previous move and the computer’s reply, if already played, will be undone.", "Se desharán tu última jugada y la respuesta del ordenador, si ya ha jugado.", "Votre dernier coup et la réponse de l’ordinateur, s’il a déjà joué, seront annulés.", "Dein letzter Zug und die Antwort des Computers, falls bereits gespielt, werden zurückgenommen.", "La tua ultima mossa e la risposta del computer, se già eseguita, saranno annullate.", "Seu último lance e a resposta do computador, se já jogada, serão desfeitos.", "Twój ostatni ruch i odpowiedź komputera, jeśli już nastąpiła, zostaną cofnięte."],
        "Голос недоступен": ["Голос недоступний", "Voice unavailable", "Voz no disponible", "Voix indisponible", "Sprache nicht verfügbar", "Voce non disponibile", "Voz indisponível", "Głos niedostępny"],
        "Попробуйте включить микрофон ещё раз.": ["Спробуйте ввімкнути мікрофон ще раз.", "Try turning on the microphone again.", "Intenta activar el micrófono de nuevo.", "Essayez de réactiver le microphone.", "Versuche, das Mikrofon erneut einzuschalten.", "Prova a riattivare il microfono.", "Tente ativar o microfone novamente.", "Spróbuj ponownie włączyć mikrofon."],
        "Просмотр: {0} из {1}": ["Перегляд: {0} із {1}", "Review: {0} of {1}", "Revisión: {0} de {1}", "Lecture : {0} sur {1}", "Rückblick: {0} von {1}", "Revisione: {0} di {1}", "Revisão: {0} de {1}", "Przegląd: {0} z {1}"],
        "Выберите клетку назначения": ["Виберіть кінцеве поле", "Choose a destination", "Elige una casilla de destino", "Choisissez une case d’arrivée", "Zielfeld wählen", "Scegli la casa di arrivo", "Escolha a casa de destino", "Wybierz pole docelowe"],
        "Партия завершена": ["Партію завершено", "Game over", "Partida terminada", "Partie terminée", "Partie beendet", "Partita terminata", "Partida encerrada", "Koniec partii"],
        "Слушаю — назовите ход": ["Слухаю — назвіть хід", "Listening — say your move", "Escuchando — di tu jugada", "À l’écoute — dites votre coup", "Ich höre zu — nenne deinen Zug", "In ascolto — di’ la tua mossa", "Ouvindo — diga seu lance", "Słucham — powiedz ruch"],
        "Микрофон выключен": ["Мікрофон вимкнено", "Microphone off", "Micrófono desactivado", "Microphone désactivé", "Mikrofon aus", "Microfono disattivato", "Microfone desativado", "Mikrofon wyłączony"],
        "Компьютер отвечает": ["Комп’ютер відповідає", "Computer is responding", "El ordenador responde", "L’ordinateur répond", "Computer antwortet", "Il computer risponde", "O computador responde", "Komputer odpowiada"],
        "Компьютер думает": ["Комп’ютер думає", "Computer is thinking", "El ordenador piensa", "L’ordinateur réfléchit", "Computer denkt nach", "Il computer pensa", "O computador está pensando", "Komputer myśli"],
        "Зажмите и скажите ход": ["Затисніть і скажіть хід", "Hold and say your move", "Mantén pulsado y di tu jugada", "Maintenez et dites votre coup", "Gedrückt halten und Zug sagen", "Tieni premuto e di’ la mossa", "Segure e diga seu lance", "Przytrzymaj i powiedz ruch"],
        "Нажмите, чтобы вернуться к игре": ["Натисніть, щоб повернутися до гри", "Tap to return to the game", "Toca para volver a la partida", "Touchez pour revenir à la partie", "Tippen, um zur Partie zurückzukehren", "Tocca per tornare alla partita", "Toque para voltar à partida", "Dotknij, aby wrócić do gry"],
        "Повторное нажатие фигуры — отмена": ["Натисніть фігуру ще раз, щоб скасувати", "Tap the piece again to deselect", "Toca la pieza otra vez para deseleccionarla", "Retouchez la pièce pour la désélectionner", "Figur erneut antippen, um die Auswahl aufzuheben", "Tocca di nuovo il pezzo per deselezionarlo", "Toque na peça novamente para desmarcar", "Dotknij figury ponownie, aby odznaczyć"],
        "Новая партия — через меню": ["Нова партія — через меню", "Start a new game from the menu", "Inicia una nueva partida desde el menú", "Lancez une nouvelle partie depuis le menu", "Neue Partie über das Menü starten", "Avvia una nuova partita dal menu", "Inicie uma nova partida pelo menu", "Rozpocznij nową partię z menu"],
        "Отпустите, чтобы отправить ход": ["Відпустіть, щоб надіслати хід", "Release to send your move", "Suelta para enviar la jugada", "Relâchez pour envoyer le coup", "Loslassen, um den Zug zu senden", "Rilascia per inviare la mossa", "Solte para enviar o lance", "Puść, aby wysłać ruch"],
        "Разбираю записанный ход": ["Розпізнаю записаний хід", "Recognizing your recorded move", "Reconociendo la jugada grabada", "Reconnaissance du coup enregistré", "Aufgenommener Zug wird erkannt", "Riconoscimento della mossa registrata", "Reconhecendo o lance gravado", "Rozpoznawanie nagranego ruchu"],
        "Дождитесь ответа": ["Дочекайтеся відповіді", "Wait for the reply", "Espera la respuesta", "Attendez la réponse", "Warte auf die Antwort", "Attendi la risposta", "Aguarde a resposta", "Poczekaj na odpowiedź"],
        "e2e4 или конь f3": ["e2e4 або кінь f3", "e2e4 or knight f3", "e2e4 o caballo f3", "e2e4 ou cavalier f3", "e2e4 oder Springer f3", "e2e4 o cavallo f3", "e2e4 ou cavalo f3", "e2e4 lub skoczek f3"],
        "Ваш ход": ["Ваш хід", "Your turn", "Tu turno", "À vous de jouer", "Du bist am Zug", "Tocca a te", "Sua vez", "Twój ruch"],
        "Готово": ["Готово", "Done", "Listo", "Terminé", "Fertig", "Fine", "Pronto", "Gotowe"],
        "Цвет фигур": ["Колір фігур", "Piece color", "Color de las piezas", "Couleur des pièces", "Figurenfarbe", "Colore dei pezzi", "Cor das peças", "Kolor figur"],
        "○  Белые": ["○  Білі", "○  White", "○  Blancas", "○  Blancs", "○  Weiß", "○  Bianco", "○  Brancas", "○  Białe"],
        "●  Чёрные": ["●  Чорні", "●  Black", "●  Negras", "●  Noirs", "●  Schwarz", "●  Nero", "●  Pretas", "●  Czarne"],
        "Сложность": ["Складність", "Difficulty", "Dificultad", "Difficulté", "Schwierigkeit", "Difficoltà", "Dificuldade", "Trudność"],
        "Рейтинг указан приблизительно": ["Рейтинг указано приблизно", "Ratings are approximate", "Las puntuaciones son aproximadas", "Les classements sont approximatifs", "Wertungen sind ungefähre Angaben", "I punteggi sono approssimativi", "As classificações são aproximadas", "Ranking jest przybliżony"],
        "Начать партию": ["Почати партію", "Start game", "Empezar partida", "Commencer la partie", "Partie starten", "Inizia partita", "Iniciar partida", "Rozpocznij partię"],
        "Текущая партия будет заменена": ["Поточну партію буде замінено", "This replaces your current game", "Esto sustituye la partida actual", "Cela remplace votre partie en cours", "Ersetzt deine aktuelle Partie", "Sostituisce la partita attuale", "Isso substitui a partida atual", "To zastąpi bieżącą partię"],
        "Превратить пешку в…": ["Перетворити пішака на…", "Promote pawn to…", "Promover peón a…", "Promouvoir le pion en…", "Bauern umwandeln in…", "Promuovi il pedone a…", "Promover peão a…", "Promuj pionka na…"],
        "Ферзь": ["Ферзь", "Queen", "Dama", "Dame", "Dame", "Donna", "Dama", "Hetman"],
        "Выбрано": ["Вибрано", "Selected", "Seleccionado", "Sélectionné", "Ausgewählt", "Selezionato", "Selecionado", "Wybrano"],
        "Доступный ход": ["Доступний хід", "Available move", "Jugada disponible", "Coup possible", "Möglicher Zug", "Mossa disponibile", "Lance disponível", "Dostępny ruch"],
        "Голос": ["Голос", "Voice", "Voz", "Voix", "Sprache", "Voce", "Voz", "Głos"],
        "Зажмите микрофон. Когда увидите «Слушаю», назовите ход, например «е два — е четыре». Отпустите кнопку, чтобы отправить запись.": ["Затисніть мікрофон. Коли побачите «Слухаю», назвіть хід, наприклад «е два — е чотири». Відпустіть кнопку, щоб надіслати запис.", "Hold the microphone. When you see “Listening”, say a move such as “e two — e four”. Release to send the recording.", "Mantén pulsado el micrófono. Cuando veas «Escuchando», di una jugada, por ejemplo «e dos — e cuatro». Suelta para enviar la grabación.", "Maintenez le microphone. Quand «À l’écoute» apparaît, dites un coup, par exemple «e deux — e quatre». Relâchez pour envoyer l’enregistrement.", "Halte das Mikrofon gedrückt. Sobald „Ich höre zu“ erscheint, sage einen Zug, etwa „e zwei — e vier“. Loslassen sendet die Aufnahme.", "Tieni premuto il microfono. Quando appare «In ascolto», di’ una mossa, ad esempio «e due — e quattro». Rilascia per inviare la registrazione.", "Segure o microfone. Quando aparecer “Ouvindo”, diga um lance, como “e dois — e quatro”. Solte para enviar a gravação.", "Przytrzymaj mikrofon. Gdy zobaczysz „Słucham”, powiedz ruch, np. „e dwa — e cztery”. Puść, aby wysłać nagranie."],
        "Нажмите фигуру, затем клетку назначения. В этом режиме компьютер отвечает без озвучивания.": ["Натисніть фігуру, потім кінцеве поле. У цьому режимі комп’ютер відповідає без озвучення.", "Tap a piece, then its destination. In board mode the computer’s moves are not spoken.", "Toca una pieza y luego su destino. En el modo tablero, las jugadas del ordenador no se leen en voz alta.", "Touchez une pièce, puis sa destination. En mode échiquier, les coups de l’ordinateur ne sont pas annoncés.", "Tippe auf eine Figur und dann auf ihr Zielfeld. In der Brettansicht werden Computerzüge nicht angesagt.", "Tocca un pezzo, poi la casa di arrivo. In modalità scacchiera, le mosse del computer non vengono pronunciate.", "Toque em uma peça e depois no destino. No modo tabuleiro, os lances do computador não são falados.", "Dotknij figury, a potem pola docelowego. W widoku szachownicy ruchy komputera nie są odczytywane."],
        "Просмотр партии": ["Перегляд партії", "Review game", "Revisar partida", "Revoir la partie", "Partie ansehen", "Rivedi partita", "Rever partida", "Przegląd partii"],
        "Свайп влево — ход назад, вправо — вперёд. Ходы не отменяются. Кнопка со стрелкой возвращает к игре.": ["Проведіть ліворуч — хід назад, праворуч — уперед. Ходи не скасовуються. Кнопка зі стрілкою повертає до гри.", "Swipe left for the previous move, right for the next. Moves are not undone. Tap the arrow to return to the game.", "Desliza a la izquierda para retroceder y a la derecha para avanzar. Las jugadas no se deshacen. Toca la flecha para volver a la partida.", "Balayez à gauche pour reculer, à droite pour avancer. Les coups ne sont pas annulés. Touchez la flèche pour revenir à la partie.", "Nach links wischen: vorheriger Zug, nach rechts: nächster. Züge werden nicht zurückgenommen. Tippe auf den Pfeil, um zur Partie zurückzukehren.", "Scorri a sinistra per tornare indietro, a destra per avanzare. Le mosse non vengono annullate. Tocca la freccia per tornare alla partita.", "Deslize à esquerda para voltar e à direita para avançar. Os lances não são desfeitos. Toque na seta para voltar à partida.", "Przesuń w lewo, aby cofnąć podgląd, w prawo, aby przejść dalej. Ruchy nie są cofane. Dotknij strzałki, aby wrócić do gry."],
        "Отмена хода": ["Скасування ходу", "Undo", "Deshacer", "Annuler", "Zurücknehmen", "Annulla", "Desfazer", "Cofnij"],
        "Зажмите микрофон и скажите «Отмена». Ваш ход и ответ компьютера будут отменены. Также можно встряхнуть телефон.": ["Затисніть мікрофон і скажіть «Скасуй». Ваш хід і відповідь комп’ютера буде скасовано. Також можна струснути телефон.", "Hold the microphone and say “Undo”. Your move and the computer’s reply will be undone. You can also shake your phone.", "Mantén pulsado el micrófono y di «Deshacer». Se desharán tu jugada y la respuesta del ordenador. También puedes agitar el teléfono.", "Maintenez le microphone et dites «Annuler». Votre coup et la réponse de l’ordinateur seront annulés. Vous pouvez aussi secouer le téléphone.", "Halte das Mikrofon gedrückt und sage „Zurücknehmen“. Dein Zug und die Antwort des Computers werden zurückgenommen. Du kannst auch das Telefon schütteln.", "Tieni premuto il microfono e di’ «Annulla». La tua mossa e la risposta del computer saranno annullate. Puoi anche scuotere il telefono.", "Segure o microfone e diga “Desfazer”. Seu lance e a resposta do computador serão desfeitos. Você também pode agitar o telefone.", "Przytrzymaj mikrofon i powiedz „Cofnij”. Twój ruch i odpowiedź komputera zostaną cofnięte. Możesz też potrząsnąć telefonem."],
        "Ход отменён": ["Хід скасовано", "Move undone", "Jugada deshecha", "Coup annulé", "Zug zurückgenommen", "Mossa annullata", "Lance desfeito", "Ruch cofnięty"],
        "Пока нечего отменять.": ["Поки немає чого скасовувати.", "There is no move to undo yet.", "Aún no hay jugadas que deshacer.", "Il n’y a pas encore de coup à annuler.", "Es gibt noch keinen Zug zum Zurücknehmen.", "Non ci sono ancora mosse da annullare.", "Ainda não há lance para desfazer.", "Nie ma jeszcze ruchów do cofnięcia."],
        "Понятно": ["Зрозуміло", "Got it", "Entendido", "Compris", "Verstanden", "Ho capito", "Entendi", "Rozumiem"],
        "Компьютер рассчитывает следующий ход": ["Комп’ютер розраховує наступний хід", "Computer is calculating its next move", "El ordenador calcula su próxima jugada", "L’ordinateur calcule son prochain coup", "Computer berechnet seinen nächsten Zug", "Il computer calcola la prossima mossa", "O computador calcula o próximo lance", "Komputer oblicza następny ruch"],
        "Распознаю ваш ход": ["Розпізнаю ваш хід", "Recognizing your move", "Reconociendo tu jugada", "Reconnaissance de votre coup", "Dein Zug wird erkannt", "Riconoscimento della tua mossa", "Reconhecendo seu lance", "Rozpoznawanie twojego ruchu"],
        "Слушаю ваш следующий ход": ["Слухаю ваш наступний хід", "Listening for your next move", "Escuchando tu próxima jugada", "À l’écoute de votre prochain coup", "Ich höre auf deinen nächsten Zug", "In ascolto della prossima mossa", "Ouvindo seu próximo lance", "Czekam na twój następny ruch"],
        "Следующий ход. Микрофон выключен": ["Наступний хід. Мікрофон вимкнено", "Next move. Microphone off", "Siguiente jugada. Micrófono desactivado", "Coup suivant. Microphone désactivé", "Nächster Zug. Mikrofon aus", "Prossima mossa. Microfono disattivato", "Próximo lance. Microfone desativado", "Następny ruch. Mikrofon wyłączony"],
        "{0}. Повторить ход компьютера": ["{0}. Повторити хід комп’ютера", "{0}. Repeat the computer’s move", "{0}. Repetir la jugada del ordenador", "{0}. Répéter le coup de l’ordinateur", "{0}. Computerzug wiederholen", "{0}. Ripeti la mossa del computer", "{0}. Repetir o lance do computador", "{0}. Powtórz ruch komputera"],
        "Представьте доску. Первый ход — ваш.": ["Уявіть дошку. Перший хід — ваш.", "Picture the board. You move first.", "Imagina el tablero. Tú juegas primero.", "Imaginez l’échiquier. Vous commencez.", "Stell dir das Brett vor. Du beginnst.", "Immagina la scacchiera. Tocca a te iniziare.", "Imagine o tabuleiro. Você começa.", "Wyobraź sobie szachownicę. Zaczynasz."],
        "Партия сохранена. Можно продолжать.": ["Партію збережено. Можна продовжувати.", "Game saved. You can continue.", "Partida guardada. Puedes continuar.", "Partie enregistrée. Vous pouvez continuer.", "Partie gespeichert. Du kannst weiterspielen.", "Partita salvata. Puoi continuare.", "Partida salva. Você pode continuar.", "Partia zapisana. Możesz kontynuować."],
        "Распознаю ход": ["Розпізнаю хід", "Recognizing move", "Reconociendo jugada", "Reconnaissance du coup", "Zug wird erkannt", "Riconoscimento della mossa", "Reconhecendo lance", "Rozpoznawanie ruchu"],
        "Озвучиваю ход": ["Озвучую хід", "Speaking move", "Leyendo jugada", "Annonce du coup", "Zug wird angesagt", "Annuncio della mossa", "Falando o lance", "Odczytywanie ruchu"],
        "Слушаю ваш ход": ["Слухаю ваш хід", "Listening for your move", "Escuchando tu jugada", "À l’écoute de votre coup", "Ich höre auf deinen Zug", "In ascolto della tua mossa", "Ouvindo seu lance", "Słucham twojego ruchu"],
        "Вам шах": ["Вам шах", "You are in check", "Estás en jaque", "Vous êtes en échec", "Du stehst im Schach", "Sei sotto scacco", "Você está em xeque", "Twój król jest szachowany"],
        "Ваш ход: {0}": ["Ваш хід: {0}", "Your move: {0}", "Tu jugada: {0}", "Votre coup : {0}", "Dein Zug: {0}", "La tua mossa: {0}", "Seu lance: {0}", "Twój ruch: {0}"],
        "Не удалось рассчитать ход Stockfish. Попробуйте ещё раз.": ["Не вдалося розрахувати хід Stockfish. Спробуйте ще раз.", "Stockfish could not calculate a move. Please try again.", "Stockfish no pudo calcular una jugada. Inténtalo de nuevo.", "Stockfish n’a pas pu calculer de coup. Réessayez.", "Stockfish konnte keinen Zug berechnen. Versuche es erneut.", "Stockfish non ha potuto calcolare una mossa. Riprova.", "O Stockfish não conseguiu calcular um lance. Tente novamente.", "Stockfish nie obliczył ruchu. Spróbuj ponownie."],
        "Stockfish не вернул допустимый ход. Попробуйте ещё раз.": ["Stockfish не повернув допустимий хід. Спробуйте ще раз.", "Stockfish did not return a legal move. Please try again.", "Stockfish no devolvió una jugada legal. Inténtalo de nuevo.", "Stockfish n’a pas renvoyé de coup légal. Réessayez.", "Stockfish hat keinen gültigen Zug geliefert. Versuche es erneut.", "Stockfish non ha restituito una mossa legale. Riprova.", "O Stockfish não retornou um lance legal. Tente novamente.", "Stockfish nie zwrócił prawidłowego ruchu. Spróbuj ponownie."],
        " Шах.": [" Шах.", " Check.", " Jaque.", " Échec.", " Schach.", " Scacco.", " Xeque.", " Szach."],
        "Компьютер: {0}. Ваш ход.": ["Комп’ютер: {0}. Ваш хід.", "Computer: {0}. Your turn.", "Ordenador: {0}. Tu turno.", "Ordinateur : {0}. À vous de jouer.", "Computer: {0}. Du bist am Zug.", "Computer: {0}. Tocca a te.", "Computador: {0}. Sua vez.", "Komputer: {0}. Twój ruch."],
        "Последний ход компьютера. ": ["Останній хід комп’ютера. ", "The computer’s last move. ", "Última jugada del ordenador. ", "Dernier coup de l’ordinateur. ", "Letzter Computerzug. ", "Ultima mossa del computer. ", "Último lance do computador. ", "Ostatni ruch komputera. "],
        "Компьютер ещё не ходил. Ваш ход.": ["Комп’ютер ще не ходив. Ваш хід.", "The computer has not moved yet. Your turn.", "El ordenador aún no ha jugado. Tu turno.", "L’ordinateur n’a pas encore joué. À vous de jouer.", "Der Computer hat noch nicht gezogen. Du bist am Zug.", "Il computer non ha ancora mosso. Tocca a te.", "O computador ainda não jogou. Sua vez.", "Komputer jeszcze nie wykonał ruchu. Twój ruch."],
        "Ход отменён. {0} ходят.": ["Хід скасовано. Ходять {0}.", "Move undone. {0} to move.", "Jugada deshecha. Juegan {0}.", "Coup annulé. Trait aux {0}.", "Zug zurückgenommen. {0} ist am Zug.", "Mossa annullata. Muove {0}.", "Lance desfeito. Vez das {0}.", "Ruch cofnięty. Ruch mają {0}."],
        "Вы играете чёрными. Компьютер начинает.": ["Ви граєте чорними. Комп’ютер починає.", "You are playing Black. The computer moves first.", "Juegas con negras. El ordenador empieza.", "Vous jouez les noirs. L’ordinateur commence.", "Du spielst Schwarz. Der Computer beginnt.", "Giochi con il nero. Il computer inizia.", "Você joga de pretas. O computador começa.", "Grasz czarnymi. Komputer zaczyna."],
        "Разрешите доступ к микрофону в Настройках iPhone → Приложения → Blind Chess.": ["Дозвольте доступ до мікрофона в Параметрах iPhone → Програми → Blind Chess.", "Allow microphone access in iPhone Settings → Apps → Blind Chess.", "Permite el acceso al micrófono en Ajustes del iPhone → Apps → Blind Chess.", "Autorisez le microphone dans Réglages de l’iPhone → Apps → Blind Chess.", "Erlaube den Mikrofonzugriff unter iPhone-Einstellungen → Apps → Blind Chess.", "Consenti l’accesso al microfono in Impostazioni iPhone → App → Blind Chess.", "Permita o acesso ao microfone em Ajustes do iPhone → Apps → Blind Chess.", "Zezwól na mikrofon w Ustawieniach iPhone’a → Aplikacje → Blind Chess."],
        "Готовим распознавание голоса…": ["Готуємо розпізнавання голосу…", "Preparing voice recognition…", "Preparando reconocimiento de voz…", "Préparation de la reconnaissance vocale…", "Spracherkennung wird vorbereitet…", "Preparazione del riconoscimento vocale…", "Preparando reconhecimento de voz…", "Przygotowywanie rozpoznawania mowy…"],
        "Модель уже на телефоне. Готовим её к работе без интернета.": ["Модель уже на телефоні. Готуємо її до роботи без інтернету.", "The model is on your phone. Preparing it to work offline.", "El modelo ya está en el teléfono. Lo preparamos para funcionar sin internet.", "Le modèle est sur votre téléphone. Préparation pour une utilisation hors ligne.", "Das Modell ist auf deinem Telefon. Es wird für die Nutzung ohne Internet vorbereitet.", "Il modello è sul telefono. Lo prepariamo per funzionare senza internet.", "O modelo está no telefone. Preparando para funcionar sem internet.", "Model jest na telefonie. Przygotowujemy go do pracy bez internetu."],
        "Загружаю Whisper": ["Завантажую Whisper", "Downloading Whisper", "Descargando Whisper", "Téléchargement de Whisper", "Whisper wird heruntergeladen", "Download di Whisper", "Baixando Whisper", "Pobieranie Whisper"],
        "Не удалось подготовить Whisper. Для первой загрузки нужно около 220 МБ, свободное место и интернет. Попробуйте снова.\n{0}": ["Не вдалося підготувати Whisper. Для першого завантаження потрібно близько 220 МБ, вільне місце та інтернет. Спробуйте ще раз.\n{0}", "Could not prepare Whisper. The first download needs about 220 MB, free space and internet. Please try again.\n{0}", "No se pudo preparar Whisper. La primera descarga requiere unos 220 MB, espacio libre e internet. Inténtalo de nuevo.\n{0}", "Impossible de préparer Whisper. Le premier téléchargement nécessite environ 220 Mo, de l’espace libre et internet. Réessayez.\n{0}", "Whisper konnte nicht vorbereitet werden. Der erste Download benötigt etwa 220 MB, freien Speicher und Internet. Versuche es erneut.\n{0}", "Impossibile preparare Whisper. Il primo download richiede circa 220 MB, spazio libero e internet. Riprova.\n{0}", "Não foi possível preparar o Whisper. O primeiro download precisa de cerca de 220 MB, espaço livre e internet. Tente novamente.\n{0}", "Nie udało się przygotować Whisper. Pierwsze pobranie wymaga około 220 MB, wolnego miejsca i internetu. Spróbuj ponownie.\n{0}"],
        "Whisper ещё не готов. Нажмите микрофон, чтобы загрузить модель.": ["Whisper ще не готовий. Натисніть мікрофон, щоб завантажити модель.", "Whisper is not ready. Tap the microphone to download the model.", "Whisper no está listo. Toca el micrófono para descargar el modelo.", "Whisper n’est pas prêt. Touchez le microphone pour télécharger le modèle.", "Whisper ist nicht bereit. Tippe auf das Mikrofon, um das Modell zu laden.", "Whisper non è pronto. Tocca il microfono per scaricare il modello.", "O Whisper não está pronto. Toque no microfone para baixar o modelo.", "Whisper nie jest gotowy. Dotknij mikrofonu, aby pobrać model."],
        "Не удалось включить микрофон. Проверьте аудиоустройство.": ["Не вдалося ввімкнути мікрофон. Перевірте аудіопристрій.", "Could not turn on the microphone. Check your audio device.", "No se pudo activar el micrófono. Comprueba tu dispositivo de audio.", "Impossible d’activer le microphone. Vérifiez votre appareil audio.", "Mikrofon konnte nicht aktiviert werden. Prüfe dein Audiogerät.", "Impossibile attivare il microfono. Controlla il dispositivo audio.", "Não foi possível ativar o microfone. Verifique o dispositivo de áudio.", "Nie udało się włączyć mikrofonu. Sprawdź urządzenie audio."],
        "Запись прервалась. Включите микрофон ещё раз.": ["Запис перервався. Увімкніть мікрофон ще раз.", "Recording was interrupted. Turn on the microphone again.", "La grabación se interrumpió. Activa el micrófono de nuevo.", "L’enregistrement a été interrompu. Réactivez le microphone.", "Aufnahme unterbrochen. Schalte das Mikrofon erneut ein.", "Registrazione interrotta. Riattiva il microfono.", "A gravação foi interrompida. Ative o microfone novamente.", "Nagrywanie przerwane. Włącz mikrofon ponownie."],
        "Запись слишком длинная. Отпустите кнопку и назовите ход ещё раз.": ["Запис задовгий. Відпустіть кнопку й назвіть хід ще раз.", "Recording is too long. Release the button and say your move again.", "La grabación es demasiado larga. Suelta el botón y repite la jugada.", "L’enregistrement est trop long. Relâchez le bouton et répétez votre coup.", "Aufnahme zu lang. Lass die Taste los und sage deinen Zug erneut.", "Registrazione troppo lunga. Rilascia il pulsante e ripeti la mossa.", "A gravação está longa demais. Solte o botão e repita seu lance.", "Nagranie jest za długie. Puść przycisk i powtórz ruch."],
        "Не удалось включить микрофон: {0}": ["Не вдалося ввімкнути мікрофон: {0}", "Could not turn on the microphone: {0}", "No se pudo activar el micrófono: {0}", "Impossible d’activer le microphone : {0}", "Mikrofon konnte nicht aktiviert werden: {0}", "Impossibile attivare il microfono: {0}", "Não foi possível ativar o microfone: {0}", "Nie udało się włączyć mikrofonu: {0}"],
        "Не удалось расслышать ход. Зажмите микрофон и попробуйте ещё раз.": ["Не вдалося розчути хід. Затисніть мікрофон і спробуйте ще раз.", "Could not hear your move. Hold the microphone and try again.", "No se ha oído tu jugada. Mantén pulsado el micrófono e inténtalo de nuevo.", "Votre coup n’a pas été entendu. Maintenez le microphone et réessayez.", "Dein Zug war nicht zu hören. Halte das Mikrofon gedrückt und versuche es erneut.", "La mossa non era udibile. Tieni premuto il microfono e riprova.", "Não foi possível ouvir seu lance. Segure o microfone e tente novamente.", "Nie słychać ruchu. Przytrzymaj mikrofon i spróbuj ponownie."],
        "Не удалось распознать ход. Попробуйте произнести его ещё раз.": ["Не вдалося розпізнати хід. Спробуйте вимовити його ще раз.", "Could not recognize your move. Please say it again.", "No se pudo reconocer tu jugada. Repítela.", "Votre coup n’a pas été reconnu. Répétez-le.", "Dein Zug wurde nicht erkannt. Sage ihn erneut.", "La mossa non è stata riconosciuta. Ripetila.", "Não foi possível reconhecer seu lance. Repita.", "Nie udało się rozpoznać ruchu. Powtórz go."],
        "Не удалось включить звук: {0}": ["Не вдалося ввімкнути звук: {0}", "Could not turn on audio: {0}", "No se pudo activar el audio: {0}", "Impossible d’activer l’audio : {0}", "Audio konnte nicht aktiviert werden: {0}", "Impossibile attivare l’audio: {0}", "Não foi possível ativar o áudio: {0}", "Nie udało się włączyć dźwięku: {0}"],
        "Короткая рокировка": ["Коротка рокіровка", "Kingside castling", "Enroque corto", "Petit roque", "Kurze Rochade", "Arrocco corto", "Roque pequeno", "Krótka roszada"],
        "Длинная рокировка": ["Довга рокіровка", "Queenside castling", "Enroque largo", "Grand roque", "Lange Rochade", "Arrocco lungo", "Roque grande", "Długa roszada"],
        ", превращение: ": [", перетворення: ", ", promoting to ", ", promoción a ", ", promotion en ", ", Umwandlung in ", ", promozione a ", ", promoção a ", ", promocja na "],
        "Мат. {0} победили.": ["Мат. Перемогли {0}.", "Checkmate. {0} wins.", "Jaque mate. Ganan {0}.", "Échec et mat. Les {0} gagnent.", "Schachmatt. {0} gewinnt.", "Scacco matto. Vince {0}.", "Xeque-mate. As {0} vencem.", "Mat. Wygrywają {0}."],
        "Ничья: пат.": ["Нічия: пат.", "Draw by stalemate.", "Tablas por ahogado.", "Nulle par pat.", "Remis durch Patt.", "Patta per stallo.", "Empate por afogamento.", "Remis przez pat."],
        "Ничья: недостаточно материала.": ["Нічия: недостатньо матеріалу.", "Draw by insufficient material.", "Tablas por material insuficiente.", "Nulle par matériel insuffisant.", "Remis wegen unzureichenden Materials.", "Patta per materiale insufficiente.", "Empate por material insuficiente.", "Remis z powodu niewystarczającego materiału."],
        "Ничья по правилу 50 ходов.": ["Нічия за правилом 50 ходів.", "Draw by the fifty-move rule.", "Tablas por la regla de las 50 jugadas.", "Nulle par la règle des cinquante coups.", "Remis nach der 50-Züge-Regel.", "Patta per la regola delle cinquanta mosse.", "Empate pela regra dos cinquenta lances.", "Remis na mocy reguły 50 ruchów."],
        "Ничья: троекратное повторение.": ["Нічия: триразове повторення.", "Draw by threefold repetition.", "Tablas por triple repetición.", "Nulle par triple répétition.", "Remis durch dreifache Stellungswiederholung.", "Patta per triplice ripetizione.", "Empate por repetição tripla.", "Remis przez trzykrotne powtórzenie pozycji."],
        "Начинающий": ["Початківець", "Beginner", "Principiante", "Débutant", "Anfänger", "Principiante", "Iniciante", "Początkujący"],
        "Любитель": ["Аматор", "Amateur", "Aficionado", "Amateur", "Amateur", "Dilettante", "Amador", "Amator"],
        "Сильный любитель": ["Сильний аматор", "Strong amateur", "Aficionado fuerte", "Amateur de bon niveau", "Starker Amateur", "Dilettante forte", "Amador forte", "Silny amator"],
        "Кандидат в мастера": ["Кандидат у майстри", "Candidate master", "Candidato a maestro", "Candidat maître", "Meisteranwärter", "Candidato maestro", "Candidato a mestre", "Kandydat na mistrza"],
        "Мастер": ["Майстер", "Master", "Maestro", "Maître", "Meister", "Maestro", "Mestre", "Mistrz"],
        "Максимальная сила": ["Максимальна сила", "Maximum strength", "Fuerza máxima", "Force maximale", "Maximale Spielstärke", "Forza massima", "Força máxima", "Maksymalna siła"],
        "Минимальная сила Stockfish": ["Мінімальна сила Stockfish", "Minimum Stockfish strength", "Fuerza mínima de Stockfish", "Force minimale de Stockfish", "Minimale Stockfish-Spielstärke", "Forza minima di Stockfish", "Força mínima do Stockfish", "Minimalna siła Stockfish"],
        "Без ограничения силы · до 3 с на ход": ["Без обмеження сили · до 3 с на хід", "Full strength · up to 3 s per move", "Máxima fuerza · hasta 3 s por jugada", "Force maximale · jusqu’à 3 s par coup", "Volle Stärke · bis zu 3 s pro Zug", "Forza piena · fino a 3 s per mossa", "Força total · até 3 s por lance", "Pełna siła · do 3 s na ruch"],
        "Ориентир {0} · Stockfish": ["Орієнтир {0} · Stockfish", "Approx. {0} · Stockfish", "Aprox. {0} · Stockfish", "Env. {0} · Stockfish", "Etwa {0} · Stockfish", "Circa {0} · Stockfish", "Aprox. {0} · Stockfish", "Około {0} · Stockfish"],
        "На доске есть только поля от а один до аш восемь.": ["На дошці є лише поля від а один до аш вісім.", "The board only has squares from a one to h eight.", "El tablero solo tiene casillas desde a uno hasta hache ocho.", "L’échiquier ne comporte que les cases de a un à ache huit.", "Das Brett hat nur Felder von a eins bis ha acht.", "La scacchiera ha solo case da a uno ad acca otto.", "O tabuleiro só tem casas de a um até agá oito.", "Szachownica ma tylko pola od a jeden do ha osiem."],
        "На поле {0} нет фигуры.": ["На полі {0} немає фігури.", "There is no piece on {0}.", "No hay ninguna pieza en {0}.", "Il n’y a pas de pièce en {0}.", "Auf {0} steht keine Figur.", "Non c’è alcun pezzo in {0}.", "Não há peça em {0}.", "Na polu {0} nie ma figury."],
        "На поле {0} фигура соперника. Сейчас ходят {1}.": ["На полі {0} фігура суперника. Зараз ходять {1}.", "The piece on {0} belongs to your opponent. It is {1}’s turn.", "La pieza en {0} es del rival. Juegan {1}.", "La pièce en {0} appartient à l’adversaire. Trait aux {1}.", "Die Figur auf {0} gehört dem Gegner. {1} ist am Zug.", "Il pezzo in {0} è dell’avversario. Muove {1}.", "A peça em {0} é do adversário. É a vez das {1}.", "Figura na {0} należy do przeciwnika. Ruch mają {1}."],
        "Начальное и конечное поле совпадают. Назовите другую клетку назначения.": ["Початкове й кінцеве поля збігаються. Назвіть інше кінцеве поле.", "The starting and destination squares are the same. Name another destination.", "La casilla inicial y la de destino coinciden. Indica otro destino.", "Les cases de départ et d’arrivée sont identiques. Indiquez une autre destination.", "Start- und Zielfeld sind gleich. Nenne ein anderes Zielfeld.", "La casa di partenza e quella di arrivo coincidono. Indica un’altra destinazione.", "As casas de origem e destino são iguais. Diga outro destino.", "Pole początkowe i docelowe są takie same. Podaj inne pole docelowe."],
        "На поле {0} уже стоит ваша фигура.": ["На полі {0} вже стоїть ваша фігура.", "Your own piece is already on {0}.", "Ya hay una pieza tuya en {0}.", "Une de vos pièces occupe déjà {0}.", "Auf {0} steht bereits eine eigene Figur.", "Un tuo pezzo occupa già {0}.", "Já há uma peça sua em {0}.", "Na {0} stoi już twoja figura."],
        "Короля не берут. Нужно поставить мат.": ["Короля не беруть. Потрібно поставити мат.", "The king cannot be captured. You need to deliver checkmate.", "El rey no se captura. Hay que dar jaque mate.", "Le roi ne se capture pas. Il faut faire échec et mat.", "Der König wird nicht geschlagen. Du musst ihn mattsetzen.", "Il re non si cattura. Devi dare scacco matto.", "O rei não pode ser capturado. É preciso dar xeque-mate.", "Króla nie można zbić. Trzeba dać mata."],
        "Пешка не ходит назад или вбок.": ["Пішак не ходить назад або вбік.", "A pawn cannot move backwards or sideways.", "El peón no puede retroceder ni moverse de lado.", "Un pion ne peut ni reculer ni aller de côté.", "Ein Bauer kann nicht rückwärts oder seitwärts ziehen.", "Il pedone non può muoversi indietro o di lato.", "O peão não pode andar para trás ou para os lados.", "Pionek nie może poruszać się w tył ani w bok."],
        "Пешка может пройти две клетки только с начального ряда.": ["Пішак може пройти два поля лише з початкового ряду.", "A pawn can move two squares only from its starting rank.", "El peón solo puede avanzar dos casillas desde su fila inicial.", "Un pion ne peut avancer de deux cases que depuis sa rangée initiale.", "Ein Bauer darf nur von seiner Startreihe zwei Felder ziehen.", "Il pedone può avanzare di due case solo dalla traversa iniziale.", "O peão só pode avançar duas casas a partir da fileira inicial.", "Pionek może przejść dwa pola tylko z początkowego rzędu."],
        "Пешка ходит на одну клетку вперёд, а с начального ряда может на две.": ["Пішак ходить на одне поле вперед, а з початкового ряду може на два.", "A pawn moves one square forward, or two from its starting rank.", "El peón avanza una casilla, o dos desde su fila inicial.", "Un pion avance d’une case, ou de deux depuis sa rangée initiale.", "Ein Bauer zieht ein Feld vorwärts, von seiner Startreihe auch zwei.", "Il pedone avanza di una casa, o di due dalla traversa iniziale.", "O peão avança uma casa, ou duas a partir da fileira inicial.", "Pionek idzie o jedno pole do przodu, a z początkowego rzędu może o dwa."],
        "Пешка не берёт вперёд. Она берёт по диагонали.": ["Пішак не бере вперед. Він бере по діагоналі.", "A pawn cannot capture straight ahead. It captures diagonally.", "El peón no captura de frente. Captura en diagonal.", "Un pion ne prend pas droit devant lui. Il prend en diagonale.", "Ein Bauer schlägt nicht geradeaus, sondern diagonal.", "Il pedone non cattura in avanti. Cattura in diagonale.", "O peão não captura para a frente. Captura na diagonal.", "Pionek nie bije prosto do przodu. Bije po przekątnej."],
        "Пешка берёт только на одну клетку по диагонали вперёд.": ["Пішак бере лише на одне поле по діагоналі вперед.", "A pawn captures one square diagonally forward.", "El peón captura una casilla en diagonal hacia delante.", "Un pion prend d’une case en diagonale vers l’avant.", "Ein Bauer schlägt ein Feld diagonal nach vorne.", "Il pedone cattura di una casa in diagonale in avanti.", "O peão captura uma casa na diagonal para a frente.", "Pionek bije o jedno pole po przekątnej do przodu."],
        "На поле {0} нечего брать. Взятие на проходе сейчас недоступно.": ["На полі {0} немає що брати. Взяття на проході зараз недоступне.", "There is nothing to capture on {0}. En passant is not available.", "No hay nada que capturar en {0}. La captura al paso no está disponible.", "Il n’y a rien à prendre en {0}. La prise en passant n’est pas possible.", "Auf {0} gibt es nichts zu schlagen. En passant ist nicht möglich.", "Non c’è nulla da catturare in {0}. La presa en passant non è disponibile.", "Não há nada para capturar em {0}. A captura en passant não está disponível.", "Na {0} nie ma nic do zbicia. Bicie w przelocie jest niedostępne."],
        "Конь ходит буквой Г: две клетки в одном направлении и одна в другом.": ["Кінь ходить літерою Г: два поля в одному напрямку й одне в іншому.", "A knight moves in an L shape: two squares in one direction and one in the other.", "El caballo se mueve en L: dos casillas en una dirección y una en la otra.", "Le cavalier se déplace en L : deux cases dans une direction et une dans l’autre.", "Der Springer zieht in L-Form: zwei Felder in eine Richtung und eines quer dazu.", "Il cavallo si muove a L: due case in una direzione e una nell’altra.", "O cavalo se move em L: duas casas em uma direção e uma na outra.", "Skoczek porusza się w kształcie litery L: dwa pola w jednym kierunku i jedno w drugim."],
        "Слон ходит только по диагонали.": ["Слон ходить лише по діагоналі.", "A bishop only moves diagonally.", "El alfil solo se mueve en diagonal.", "Le fou se déplace uniquement en diagonale.", "Der Läufer zieht nur diagonal.", "L’alfiere si muove solo in diagonale.", "O bispo só se move na diagonal.", "Goniec porusza się tylko po przekątnej."],
        "Ладья ходит только по вертикали или горизонтали.": ["Тура ходить лише по вертикалі або горизонталі.", "A rook only moves along ranks or files.", "La torre solo se mueve por filas o columnas.", "La tour se déplace uniquement sur les lignes ou les colonnes.", "Der Turm zieht nur waagerecht oder senkrecht.", "La torre si muove solo lungo traverse o colonne.", "A torre só se move na horizontal ou na vertical.", "Wieża porusza się tylko wzdłuż rzędów lub kolumn."],
        "Ферзь ходит по прямой или диагонали.": ["Ферзь ходить по прямій або діагоналі.", "A queen moves in straight lines or diagonally.", "La dama se mueve en línea recta o diagonal.", "La dame se déplace en ligne droite ou en diagonale.", "Die Dame zieht gerade oder diagonal.", "La donna si muove in linea retta o in diagonale.", "A dama se move em linha reta ou na diagonal.", "Hetman porusza się po linii prostej lub po przekątnej."],
        "Король ходит на одну клетку.": ["Король ходить на одне поле.", "A king moves one square.", "El rey se mueve una casilla.", "Le roi se déplace d’une case.", "Der König zieht ein Feld.", "Il re si muove di una casa.", "O rei se move uma casa.", "Król porusza się o jedno pole."],
        "Путь перекрыт фигурой на поле {0}.": ["Шлях перекрито фігурою на полі {0}.", "The path is blocked by a piece on {0}.", "Una pieza en {0} bloquea el camino.", "Une pièce en {0} bloque le passage.", "Eine Figur auf {0} versperrt den Weg.", "Un pezzo in {0} blocca il percorso.", "Uma peça em {0} bloqueia o caminho.", "Figura na {0} blokuje drogę."],
        "На поле {0} король окажется под ударом.": ["На полі {0} король опиниться під ударом.", "The king would be under attack on {0}.", "El rey quedaría amenazado en {0}.", "Le roi serait attaqué en {0}.", "Auf {0} wäre der König bedroht.", "Il re sarebbe sotto attacco in {0}.", "O rei ficaria sob ataque em {0}.", "Na {0} król byłby atakowany."],
        "Вашему королю шах. Этот ход не защищает от шаха.": ["Вашому королю шах. Цей хід не захищає від шаху.", "Your king is in check. This move does not resolve it.", "Tu rey está en jaque. Esta jugada no lo evita.", "Votre roi est en échec. Ce coup ne le protège pas.", "Dein König steht im Schach. Dieser Zug wehrt das Schach nicht ab.", "Il tuo re è sotto scacco. Questa mossa non lo risolve.", "Seu rei está em xeque. Este lance não resolve o xeque.", "Twój król jest szachowany. Ten ruch nie usuwa szacha."],
        "После этого хода ваш король окажется под шахом.": ["Після цього ходу ваш король опиниться під шахом.", "This move would leave your king in check.", "Esta jugada dejaría a tu rey en jaque.", "Ce coup laisserait votre roi en échec.", "Dieser Zug würde deinen König ins Schach stellen.", "Questa mossa lascerebbe il tuo re sotto scacco.", "Este lance deixaria seu rei em xeque.", "Ten ruch pozostawiłby twojego króla pod szachem."],
        "Рокировка на эту сторону недоступна: король или ладья уже ходили, либо ладьи нет на месте.": ["Рокіровка на цей бік недоступна: король або тура вже ходили, або тури немає на місці.", "You cannot castle on this side: the king or rook has moved, or the rook is missing.", "No puedes enrocar por ese lado: el rey o la torre ya se han movido, o falta la torre.", "Le roque de ce côté est impossible : le roi ou la tour a bougé, ou la tour est absente.", "Diese Rochade ist nicht möglich: König oder Turm haben bereits gezogen, oder der Turm fehlt.", "L’arrocco su questo lato non è possibile: re o torre si sono già mossi, oppure manca la torre.", "Não é possível fazer roque deste lado: o rei ou a torre já se moveu, ou a torre está ausente.", "Roszada w tę stronę jest niemożliwa: król lub wieża już się poruszyły albo brakuje wieży."],
        "Нельзя рокироваться, пока король под шахом.": ["Не можна рокіруватися, поки король під шахом.", "You cannot castle while in check.", "No puedes enrocar estando en jaque.", "Vous ne pouvez pas roquer en étant en échec.", "Im Schach darfst du nicht rochieren.", "Non puoi arroccare mentre sei sotto scacco.", "Não é possível fazer roque estando em xeque.", "Nie można wykonać roszady pod szachem."],
        "Рокировке мешает фигура на поле {0}.": ["Рокіровці заважає фігура на полі {0}.", "A piece on {0} blocks castling.", "Una pieza en {0} impide el enroque.", "Une pièce en {0} empêche le roque.", "Eine Figur auf {0} verhindert die Rochade.", "Un pezzo in {0} impedisce l’arrocco.", "Uma peça em {0} impede o roque.", "Figura na {0} blokuje roszadę."],
        "Нельзя рокироваться через поле под ударом: {0}.": ["Не можна рокіруватися через поле під ударом: {0}.", "You cannot castle through an attacked square: {0}.", "No puedes enrocar pasando por una casilla atacada: {0}.", "Vous ne pouvez pas roquer en traversant une case attaquée : {0}.", "Du darfst nicht über ein bedrohtes Feld rochieren: {0}.", "Non puoi arroccare attraversando una casa attaccata: {0}.", "Não é possível fazer roque passando por uma casa atacada: {0}.", "Roszada przez atakowane pole jest niedozwolona: {0}."],
        "На это поле могут пойти несколько фигур. Назовите начальное поле.": ["На це поле можуть піти кілька фігур. Назвіть початкове поле.", "More than one piece can move there. Name the starting square.", "Varias piezas pueden ir ahí. Indica la casilla inicial.", "Plusieurs pièces peuvent aller là. Indiquez la case de départ.", "Mehrere Figuren können dorthin ziehen. Nenne das Startfeld.", "Più pezzi possono arrivare lì. Indica la casa di partenza.", "Mais de uma peça pode ir para lá. Diga a casa de origem.", "Kilka figur może tam przejść. Podaj pole początkowe."],
        "Уточните: короткая или длинная рокировка?": ["Уточніть: коротка чи довга рокіровка?", "Please specify kingside or queenside castling.", "Indica si es enroque corto o largo.", "Précisez : petit ou grand roque.", "Bitte gib kurze oder lange Rochade an.", "Specifica arrocco corto o lungo.", "Especifique roque pequeno ou grande.", "Określ, czy chodzi o krótką, czy długą roszadę."],
        "Пешку можно превратить только в ферзя, ладью, слона или коня.": ["Пішака можна перетворити лише на ферзя, туру, слона або коня.", "A pawn can promote only to a queen, rook, bishop or knight.", "Un peón solo puede promover a dama, torre, alfil o caballo.", "Un pion ne peut être promu qu’en dame, tour, fou ou cavalier.", "Ein Bauer kann nur in Dame, Turm, Läufer oder Springer umgewandelt werden.", "Un pedone può essere promosso solo a donna, torre, alfiere o cavallo.", "Um peão só pode ser promovido a dama, torre, bispo ou cavalo.", "Pionka można promować tylko na hetmana, wieżę, gońca lub skoczka."],
        "Превращение возможно только на последнем ряду.": ["Перетворення можливе лише на останньому ряду.", "Promotion is only possible on the last rank.", "La promoción solo es posible en la última fila.", "La promotion n’est possible que sur la dernière rangée.", "Umwandlung ist nur auf der letzten Reihe möglich.", "La promozione è possibile solo sull’ultima traversa.", "A promoção só é possível na última fileira.", "Promocja jest możliwa tylko w ostatnim rzędzie."],
        "На поле {0} нет фигуры для взятия.": ["На полі {0} немає фігури для взяття.", "There is no piece to capture on {0}.", "No hay ninguna pieza que capturar en {0}.", "Il n’y a pas de pièce à prendre en {0}.", "Auf {0} steht keine Figur zum Schlagen.", "Non c’è alcun pezzo da catturare in {0}.", "Não há peça para capturar em {0}.", "Na {0} nie ma figury do zbicia."],
        "Не разобрал поля. Назовите начальное и конечное, например: е два, е четыре.": ["Не вдалося розібрати поля. Назвіть початкове й кінцеве, наприклад: е два, е чотири.", "Could not identify the squares. Say the starting and destination squares, for example: e two, e four.", "No se identificaron las casillas. Di origen y destino, por ejemplo: e dos, e cuatro.", "Les cases n’ont pas été reconnues. Dites le départ et l’arrivée, par exemple : e deux, e quatre.", "Die Felder wurden nicht erkannt. Nenne Start und Ziel, zum Beispiel: e zwei, e vier.", "Case non riconosciute. Di’ partenza e arrivo, ad esempio: e due, e quattro.", "As casas não foram identificadas. Diga origem e destino, por exemplo: e dois, e quatro.", "Nie rozpoznano pól. Podaj pole początkowe i docelowe, na przykład: e dwa, e cztery."],
        "На поле {0} стоит {1}, а не названная фигура.": ["На полі {0} стоїть {1}, а не названа фігура.", "The piece on {0} is a {1}, not the piece you named.", "La pieza en {0} es {1}, no la que has nombrado.", "La pièce en {0} est de type {1}, pas celle indiquée.", "Auf {0} steht die Figur {1}, nicht die genannte Figur.", "Il pezzo in {0} è di tipo {1}, non quello indicato.", "A peça em {0} é do tipo {1}, não a peça indicada.", "Na {0} stoi {1}, a nie wskazana figura."],
        "Уточните превращение: ферзь, ладья, слон или конь.": ["Уточніть перетворення: ферзь, тура, слон або кінь.", "Specify the promotion: queen, rook, bishop or knight.", "Indica la promoción: dama, torre, alfil o caballo.", "Précisez la promotion : dame, tour, fou ou cavalier.", "Gib die Umwandlung an: Dame, Turm, Läufer oder Springer.", "Specifica la promozione: donna, torre, alfiere o cavallo.", "Especifique a promoção: dama, torre, bispo ou cavalo.", "Podaj figurę do promocji: hetman, wieża, goniec lub skoczek."],
        "У вас нет такой фигуры на доске.": ["У вас немає такої фігури на дошці.", "You do not have that type of piece on the board.", "No tienes ninguna pieza de ese tipo en el tablero.", "Vous n’avez pas de pièce de ce type sur l’échiquier.", "Du hast keine solche Figur auf dem Brett.", "Non hai pezzi di questo tipo sulla scacchiera.", "Você não tem esse tipo de peça no tabuleiro.", "Nie masz takiej figury na szachownicy."],
        "Не нахожу допустимого хода на поле {0}. Назовите начальное поле.": ["Не знаходжу допустимого ходу на поле {0}. Назвіть початкове поле.", "No legal move to {0} found. Name the starting square.", "No hay jugada legal a {0}. Indica la casilla inicial.", "Aucun coup légal vers {0}. Indiquez la case de départ.", "Kein gültiger Zug nach {0} gefunden. Nenne das Startfeld.", "Nessuna mossa legale verso {0}. Indica la casa di partenza.", "Nenhum lance legal para {0}. Diga a casa de origem.", "Brak prawidłowego ruchu na {0}. Podaj pole początkowe."],
        "Белые": ["Білі", "White", "Blancas", "Blancs", "Weiß", "Bianco", "Brancas", "Białe"],
        "Чёрные": ["Чорні", "Black", "Negras", "Noirs", "Schwarz", "Nero", "Pretas", "Czarne"],
        "пешка": ["пішак", "pawn", "peón", "pion", "Bauer", "pedone", "peão", "pionek"],
        "конь": ["кінь", "knight", "caballo", "cavalier", "Springer", "cavallo", "cavalo", "skoczek"],
        "слон": ["слон", "bishop", "alfil", "fou", "Läufer", "alfiere", "bispo", "goniec"],
        "ладья": ["тура", "rook", "torre", "tour", "Turm", "torre", "torre", "wieża"],
        "ферзь": ["ферзь", "queen", "dama", "dame", "Dame", "donna", "dama", "hetman"],
        "король": ["король", "king", "rey", "roi", "König", "re", "rei", "król"],
        "пусто": ["порожньо", "empty", "vacío", "vide", "leer", "vuoto", "vazio", "puste"],
        "берёт": ["бере", "takes", "captura", "prend", "schlägt", "prende", "captura", "bije"],
        "на": ["на", "to", "a", "en", "nach", "in", "para", "na"],
        "Настройки": ["Налаштування", "Settings", "Ajustes", "Réglages", "Einstellungen", "Impostazioni", "Ajustes", "Ustawienia"],
        "Язык": ["Мова", "Language", "Idioma", "Langue", "Sprache", "Lingua", "Idioma", "Język"],
        "Язык интерфейса и голосовых команд": ["Мова інтерфейсу й голосових команд", "Interface and voice command language", "Idioma de la interfaz y los comandos de voz", "Langue de l’interface et des commandes vocales", "Sprache für Oberfläche und Sprachbefehle", "Lingua dell’interfaccia e dei comandi vocali", "Idioma da interface e dos comandos de voz", "Język interfejsu i poleceń głosowych"],
    ]
}

func L(_ key: String, _ arguments: String...) -> String {
    localizedText(key, language: AppLanguage.current, arguments: arguments)
}

func localizedText(_ key: String, language: AppLanguage, arguments: [String] = []) -> String {
    var text = key
    if let index = language.translationIndex, let values = AppStrings.translations[key], values.indices.contains(index) {
        text = values[index]
    }
    for (index, value) in arguments.enumerated() {
        text = text.replacingOccurrences(of: "{\(index)}", with: value)
    }
    return text
}

extension AppLanguage {
    // Translate command vocabulary to the existing parser's canonical language.
    // Match whole words so ordinary prose cannot accidentally become coordinates.
    func canonicalCommand(_ text: String) -> String {
        guard self != .ru else { return text }
        var input = text.lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .replacingOccurrences(of: "ʼ", with: "'")
        input = canonicalCoordinateNames(input)
        let words: [String: String]
        if self == .en {
            words = ["pawn": "пешка", "knight": "конь", "night": "конь", "bishop": "слон",
                     "rook": "ладья", "queen": "ферзь", "king": "король",
                     "one": "1", "two": "2", "three": "3", "four": "4", "five": "5", "six": "6", "seven": "7", "eight": "8",
                     "ay": "a", "bee": "b", "be": "b", "see": "c", "sea": "c", "dee": "d", "ee": "e",
                     "ef": "f", "eff": "f", "gee": "g", "aitch": "h", "eitch": "h",
                     "king side": "короткая", "queen side": "длинная", "kingside": "короткая", "queenside": "длинная",
                     "short": "короткая", "long": "длинная", "castle": "рокировка", "castles": "рокировка", "castling": "рокировка",
                     "takes": "берет", "take": "берет", "captures": "берет", "capture": "берет",
                     "promote to": "превращение", "promotes to": "превращение", "promote": "превращение", "promotion": "превращение",
                     "from": "из", "to": "на", "on": "на", "repeat": "повтори", "again": "повтори",
                     "undo": "отмена", "back": "назад", "pause": "пауза", "stop": "стоп"]
        } else if self == .uk {
            words = ["пішак": "пешка", "пішака": "пешка", "пішаком": "пешка", "кінь": "конь", "конем": "конь", "коня": "конь",
                     "тура": "ладья", "туру": "ладья", "турою": "ладья", "слоном": "слон", "слона": "слон",
                     "ферзем": "ферзь", "ферзя": "ферзь", "королем": "король", "короля": "король",
                     "чотири": "4", "п'ять": "5", "пять": "5", "шість": "6", "сім": "7", "вісім": "8",
                     "еф": "f", "джі": "g", "ґе": "g", "ґ": "g", "ейч": "h", "ей": "a",
                     "рокіровка": "рокировка", "рокірування": "рокировка", "рокіруй": "рокировка",
                     "коротка": "короткая", "довга": "длинная", "довге": "длинная", "коротке": "короткая",
                     "бере": "берет", "б'є": "бьет", "взяття": "берет", "перетворення": "превращение", "перетворити": "превращение",
                     "повтори": "повтори", "повторити": "повтори", "скасувати": "отмена", "скасуй": "отмена", "назад": "назад", "від": "от", "з": "из", "із": "из"]
        } else {
            words = commandVocabulary
        }
        if self == .es || self == .it || self == .fr {
            // "a" is both the file and a destination preposition. Keep a-rank pairs.
            let rankWords = coordinateRanks.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
            input = input.replacingOccurrences(of: "\\ba\\b(?!\\s*(?:[1-8]|" + rankWords + ")(?![\\p{L}]))", with: "на", options: .regularExpression)
        }
        // One regex pass prevents a replacement from being translated a second time.
        let keys = words.keys.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:))
        let pattern = "(?<![\\p{L}])(?:" + keys.joined(separator: "|") + ")(?![\\p{L}])"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        let matches = regex.matches(in: input, range: NSRange(input.startIndex..., in: input))
        for match in matches.reversed() {
            guard let range = Range(match.range, in: input), let replacement = words[String(input[range])] else { continue }
            input.replaceSubrange(range, with: replacement)
        }
        return input
    }
}

extension AppLanguage {
    var coordinateFiles: [String] {
        switch self {
        case .es: return ["a", "be", "ce", "de", "e", "efe", "ge", "hache"]
        case .fr: return ["a", "bé", "cé", "dé", "e", "effe", "gé", "ache"]
        case .de: return ["a", "be", "ce", "de", "e", "ef", "ge", "ha"]
        case .it: return ["a", "bi", "ci", "di", "e", "effe", "gi", "acca"]
        case .pt: return ["a", "bê", "cê", "dê", "e", "efe", "gê", "agá"]
        case .pl: return ["a", "be", "ce", "de", "e", "ef", "gie", "ha"]
        default: return Array("abcdefgh").map(String.init)
        }
    }
    var coordinateRanks: [String] {
        switch self {
        case .es: return ["uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho"]
        case .fr: return ["un", "deux", "trois", "quatre", "cinq", "six", "sept", "huit"]
        case .de: return ["eins", "zwei", "drei", "vier", "fünf", "sechs", "sieben", "acht"]
        case .it: return ["uno", "due", "tre", "quattro", "cinque", "sei", "sette", "otto"]
        case .pt: return ["um", "dois", "três", "quatro", "cinco", "seis", "sete", "oito"]
        case .pl: return ["jeden", "dwa", "trzy", "cztery", "pięć", "sześć", "siedem", "osiem"]
        default: return (1...8).map(String.init)
        }
    }
    var undoCommands: Set<String> {
        switch self {
        case .es: return ["deshacer", "deshacer jugada", "deshacer la jugada", "deshacer la última jugada", "deshacer la ultima jugada"]
        case .fr: return ["annuler", "annule", "annuler le coup", "annule le coup", "annuler le dernier coup"]
        case .de: return ["zurücknehmen", "zuruecknehmen", "zug zurücknehmen", "letzten zug zurücknehmen", "rückgängig", "rückgängig machen"]
        case .it: return ["annulla", "annullare", "annulla mossa", "annulla la mossa", "annulla l ultima mossa"]
        case .pt: return ["desfazer", "desfazer lance", "desfazer o lance", "desfazer o último lance", "desfazer o ultimo lance"]
        case .pl: return ["cofnij", "cofnij ruch", "cofnij ostatni ruch", "cofnąć", "cofnac"]
        default: return []
        }
    }
    /// Vocabulary is language-specific. File names are resolved only next to a rank,
    /// before prepositions (French "de", Italian "di") are translated.
    var commandVocabulary: [String: String] {
        var words: [String: String]
        switch self {
        case .es:
            words = ["peón":"пешка", "caballo":"конь", "alfil":"слон", "torre":"ладья", "dama":"ферзь", "reina":"ферзь", "rey":"король",
                     "enroque corto":"короткая рокировка", "enroque largo":"длинная рокировка", "enroque":"рокировка",
                     "captura":"берет", "toma":"берет", "por":"берет", "promoción a":"превращение", "promociona a":"превращение", "promover a":"превращение", "promoción":"превращение",
                     "desde":"из", "de":"из", "hasta":"на", "en":"на", "repite":"повтори", "otra vez":"повтори", "pausa":"пауза", "para":"стоп"]
        case .fr:
            words = ["pion":"пешка", "cavalier":"конь", "fou":"слон", "tour":"ладья", "dame":"ферзь", "reine":"ферзь", "roi":"король",
                     "petit roque":"короткая рокировка", "grand roque":"длинная рокировка", "roque":"рокировка",
                     "prend":"берет", "prends":"берет", "capture":"берет", "promotion en":"превращение", "promouvoir en":"превращение", "promotion":"превращение",
                     "de":"из", "en":"на", "vers":"на", "à":"на", "répète":"повтори", "répéter":"повтори", "encore":"повтори", "pause":"пауза", "stop":"стоп"]
        case .de:
            words = ["bauer":"пешка", "springer":"конь", "läufer":"слон", "turm":"ладья", "dame":"ферзь", "könig":"король",
                     "kurze rochade":"короткая рокировка", "lange rochade":"длинная рокировка", "rochade":"рокировка",
                     "schlägt":"берет", "nimmt":"берет", "umwandlung in":"превращение", "umwandeln in":"превращение", "umwandlung":"превращение",
                     "von":"из", "nach":"на", "auf":"на", "wiederholen":"повтори", "noch einmal":"повтори", "pause":"пауза", "stopp":"стоп"]
        case .it:
            words = ["pedone":"пешка", "cavallo":"конь", "alfiere":"слон", "torre":"ладья", "donna":"ферзь", "regina":"ферзь", "re":"король",
                     "arrocco corto":"короткая рокировка", "arrocco lungo":"длинная рокировка", "arrocco":"рокировка",
                     "prende":"берет", "cattura":"берет", "per":"берет", "promozione a":"превращение", "promuovi a":"превращение", "promozione":"превращение",
                     "da":"из", "di":"из", "in":"на", "su":"на", "ripeti":"повтори", "ancora":"повтори", "pausa":"пауза", "stop":"стоп"]
        case .pt:
            words = ["peão":"пешка", "cavalo":"конь", "bispo":"слон", "torre":"ладья", "dama":"ферзь", "rainha":"ферзь", "rei":"король",
                     "roque pequeno":"короткая рокировка", "roque curto":"короткая рокировка", "roque grande":"длинная рокировка", "roque longo":"длинная рокировка", "roque":"рокировка",
                     "captura":"берет", "toma":"берет", "promoção a":"превращение", "promover a":"превращение", "promoção":"превращение",
                     "de":"из", "para":"на", "em":"на", "repita":"повтори", "repete":"повтори", "de novo":"повтори", "pausa":"пауза", "pare":"стоп"]
        case .pl:
            words = ["pion":"пешка", "pionek":"пешка", "pionkiem":"пешка", "skoczek":"конь", "skoczkiem":"конь", "koń":"конь", "goniec":"слон", "gońcem":"слон", "wieża":"ладья", "wieżą":"ладья", "hetman":"ферзь", "hetmanem":"ферзь", "król":"король", "królem":"король",
                     "krótka roszada":"короткая рокировка", "roszada krótka":"короткая рокировка", "długa roszada":"длинная рокировка", "roszada długa":"длинная рокировка", "roszada":"рокировка",
                     "bije":"берет", "bierze":"берет", "promocja na":"превращение", "promuj na":"превращение", "promocja":"превращение", "hetmana":"ферзь", "wieżę":"ладья", "gońca":"слон", "skoczka":"конь",
                     "z":"из", "na":"на", "do":"на", "powtórz":"повтори", "jeszcze raz":"повтори", "pauza":"пауза", "stop":"стоп"]
        default: return [:]
        }
        for (index, rank) in coordinateRanks.enumerated() { words[rank] = String(index + 1) }
        if self == .es { words["una"] = "1" }
        if self == .fr { words["une"] = "1" }
        if self == .de { words["ein"] = "1"; words["zwo"] = "2" }
        if self == .pt { words["uma"] = "1"; words["duas"] = "2" }
        // Whisper sometimes omits accents. Keep matching exact words, not substrings.
        for (key, value) in Array(words) {
            words[key.folding(options: .diacriticInsensitive, locale: Locale(identifier: speechLocale))] = value
        }
        if self == .fr { words.removeValue(forKey: "a") }
        return words
    }

    func canonicalCoordinateNames(_ text: String) -> String {
        guard [.es, .fr, .de, .it, .pt, .pl].contains(self) else { return text }
        var input = text
        let ranks = commandVocabulary.filter { Int($0.value) != nil }.keys
        let rankPattern = "(?:[1-8]|" + ranks.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|") + ")"
        var aliases: [String: String] = [:]
        for (index, file) in coordinateFiles.enumerated() {
            let value = String(Array("abcdefgh")[index])
            aliases[file] = value
            aliases[file.folding(options: .diacriticInsensitive, locale: Locale(identifier: speechLocale))] = value
            aliases[value] = value
        }
        if self == .fr { aliases["hache"] = "h"; aliases["èf"] = "f" }
        if self == .pt { aliases["éfe"] = "f"; aliases["guê"] = "g" }
        let pattern = "(?<![\\p{L}])(?:" + aliases.keys.sorted { $0.count > $1.count }.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|") + ")(?=[\\s-]*" + rankPattern + "(?![\\p{L}]))"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return input }
        for match in regex.matches(in: input, range: NSRange(input.startIndex..., in: input)).reversed() {
            if let range = Range(match.range, in: input), let file = aliases[String(input[range])] {
                // Space separates the canonical file from a spoken rank (e.g. "eftrzy").
                input.replaceSubrange(range, with: file + " ")
            }
        }
        return input
    }
}
