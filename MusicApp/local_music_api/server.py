# server.py
import http.server
import socketserver
import json
import os
from urllib.parse import urlparse, parse_qs
import mimetypes # Для определения типа файла (изображение, аудио и т.п.)
import urllib.parse # Для раскодирования URL

# Путь к вашему JSON-файлу
DATA_FILE = 'music_catalog.json'

# Папка, откуда сервер будет раздавать файлы (например, изображения, аудио)
STATIC_FOLDER = 'albums'

class MusicAPIHandler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        # Разбираем URL
        parsed_path = urlparse(self.path)
        path = parsed_path.path
        query_params = parse_qs(parsed_path.query)

        path_parts = path.strip('/').split('/')
        
        if path == '/search' and 'q' in query_params:
            self.handle_search_request(query_params)
            return

        # Проверяем на *специфичные* API-маршруты с ID: /albums/{id}, /songs/{id}, /artists/{id}
        # Условие: начинается с 'albums', 'songs', или 'artists' И содержит РОВНО ОДИН сегмент ID после
        if len(path_parts) == 2 and path_parts[0] in ['albums', 'songs', 'artists']:
            entity_type = path_parts[0]
            entity_id = path_parts[1]
            # Это API-запрос к конкретной сущности
            self.handle_api_entity_request(path)
            return

        # Проверяем, не является ли путь запросом к списку: /albums, /songs, /artists
        # Условие: состоит только из одного сегмента 'albums', 'songs', или 'artists'
        if len(path_parts) == 1 and path in ['/songs', '/albums', '/artists']:
            self.handle_api_list_request(path)
            return

        # Проверяем, не является ли путь запросом к файлу в папке STATIC_FOLDER
        # Условие: начинается с STATIC_FOLDER и имеет больше сегментов, чем просто STATIC_FOLDER
        # Например, /albums/A%20Night%20At%20The%20Opera/cover.jpg (path_parts = ['albums', 'A ...', 'cover.jpg'])
        # или /albums/A%20Night%20At%20The%20Opera/track.mp3 (path_parts = ['albums', 'A ...', 'track.mp3'])
        # Это должно сработать, если len(path_parts) > 1 и path_parts[0] == STATIC_FOLDER
        if len(path_parts) >= 2 and path_parts[0] == STATIC_FOLDER.split('/')[0]: # Если STATIC_FOLDER = 'albums', проверяем на 'albums'
            # Это запрос к статическому файлу
            self.handle_static_file_request(path)
            return # Завершаем обработку после отправки файла


        
        # Если ничего не подошло
        self.send_error(404, "Not Found")
        
    def handle_search_request(self, query_params):
        """Обработка поисковых запросов /search?q=query"""
        try:
            search_query = query_params.get('q', [''])[0].lower().strip()
            
            print(f"DEBUG: Search query: '{search_query}'")
            
            if not search_query:
                self.send_json_response({"songs": [], "albums": []})
                return
                
            with open(DATA_FILE, 'r', encoding='utf-8') as f:
                catalog = json.load(f)

            all_songs = catalog.get('songs', [])
            all_albums = catalog.get('albums', [])
            all_artists = catalog.get('artists', [])
            
            # 🔥 СОЗДАЕМ СЛОВАРЬ artist_id -> artist_name для быстрого поиска
            artist_names = {artist['id']: artist['name'].lower() for artist in all_artists}
            
            # 🔥 ПОИСК ПЕСЕН: по title ИЛИ по artist name
            matched_songs = []
            for song in all_songs:
                song_title = song.get('title', '').lower()
                artist_name = artist_names.get(song.get('artistID', ''), '')
                
                if (search_query in song_title or
                    search_query in artist_name):
                    matched_songs.append(song)
            
            # 🔥 ПОИСК АЛЬБОМОВ: по title ИЛИ по artist name
            matched_albums = []
            for album in all_albums:
                album_title = album.get('title', '').lower()
                artist_name = artist_names.get(album.get('artistID', ''), '')
                
                if (search_query in album_title or
                    search_query in artist_name):
                    matched_albums.append(album)

            print(f"DEBUG: Found {len(matched_songs)} songs, {len(matched_albums)} albums")
            
            results = {
                "songs": matched_songs,
                "albums": matched_albums
            }
            
            self.send_json_response(results)
            
        except FileNotFoundError:
            self.send_error(500, "Data file not found")
        except json.JSONDecodeError:
            self.send_error(500, "Error parsing data file")
           

    def handle_api_list_request(self, path):
        """Обработка запросов к API для получения списков (/songs, /albums, /artists)"""
        try:
            with open(DATA_FILE, 'r', encoding='utf-8') as f:
                catalog = json.load(f)

            if path == '/songs':
                data = catalog.get('songs', [])
            elif path == '/albums':
                data = catalog.get('albums', [])
            elif path == '/artists':
                data = catalog.get('artists', [])
            else:
                # Не должно сюда дойти, если логика do_GET верна
                data = None
                self.send_error(404, "API endpoint not found")
                return

            self.send_json_response(data)
        except FileNotFoundError:
            self.send_error(500, "Data file not found")
        except json.JSONDecodeError:
            self.send_error(500, "Error parsing data file")

    def handle_api_entity_request(self, path):
        """Обработка запросов к API для получения конкретной сущности по ID (/albums/{id}, /songs/{id}, /artists/{id})"""
        try:
            with open(DATA_FILE, 'r', encoding='utf-8') as f:
                catalog = json.load(f)

            path_parts = path.strip('/').split('/')
            if len(path_parts) < 2:
                self.send_error(404, "Invalid path")
                return

            entity_type = path_parts[0] # 'albums', 'songs', 'artists'
            entity_id = path_parts[1]   # 'album-001', 'song-001', 'artist-001'

            # Поиск сущности по ID
            if entity_type == 'albums':
                entities = catalog.get('albums', [])
            elif entity_type == 'songs':
                entities = catalog.get('songs', [])
            elif entity_type == 'artists':
                entities = catalog.get('artists', [])
            else:
                self.send_error(404, "Invalid entity type")
                return

            # Находим сущность по ID
            entity = next((item for item in entities if item['id'] == entity_id), None)

            if entity:
                self.send_json_response(entity)
            else:
                self.send_error(404, f"{entity_type[:-1].title()} with ID {entity_id} not found") # Убираем 's' для названия

        except FileNotFoundError:
            self.send_error(500, "Data file not found")
        except json.JSONDecodeError:
            self.send_error(500, "Error parsing data file")

    def handle_static_file_request(self, path):
        """Обработка запросов к статическим файлам (изображения, аудио)"""
        # path будет вроде '/albums/A Night At The Opera (Remastered 2011)/cover.jpg'
        # Нам нужно извлечь путь к файлу относительно STATIC_FOLDER и раскодировать его
        # Убираем первый слэш и раскодируем URL
        requested_file_path_unquoted = urllib.parse.unquote(path[1:]) # Например, 'albums/A Night At The Opera (Remastered 2011)/cover.jpg'

        # Отладочный вывод
        print(f"DEBUG: Handling static file request for path: {path}")
        print(f"DEBUG: Decoded path: {requested_file_path_unquoted}")

        # Проверяем, начинается ли путь с STATIC_FOLDER
        if not requested_file_path_unquoted.startswith(STATIC_FOLDER):
            print(f"DEBUG: Path does not start with STATIC_FOLDER: {STATIC_FOLDER}")
            self.send_error(404, "File not found")
            return

        # Путь к файлу относительно текущей директории сервера
        full_file_path = os.path.join(os.getcwd(), requested_file_path_unquoted)

        print(f"DEBUG: Attempting to open file at: {full_file_path}")

        # Проверяем, существует ли файл и является ли он файлом (а не папкой)
        if os.path.exists(full_file_path) and os.path.isfile(full_file_path):
            # Определяем MIME-тип файла
            mime_type, _ = mimetypes.guess_type(full_file_path)
            if mime_type is None:
                mime_type = 'application/octet-stream' # Тип по умолчанию

            try:
                # Открываем файл в бинарном режиме
                with open(full_file_path, 'rb') as file:
                    self.send_response(200)
                    self.send_header("Content-type", mime_type)
                    # Важно: разрешаем CORS, чтобы iOS-приложение могло получить доступ к серверу
                    self.send_header("Access-Control-Allow-Origin", "*")
                    # Устанавливаем Content-Length для корректной передачи
                    file_size = os.path.getsize(full_file_path)
                    self.send_header("Content-Length", str(file_size))
                    self.end_headers()
                    # Отправляем содержимое файла
                    self.wfile.write(file.read())
            except IOError:
                self.send_error(500, "Error reading file")
        else:
            print(f"DEBUG: File does not exist or is not a file: {full_file_path}")
            self.send_error(404, "File not found")


    def send_json_response(self, data):
        """Отправка JSON-ответа"""
        # Проверяем, был ли объект найден (для конкретных сущностей)
        if data is None:
            self.send_error(404, "Not Found")
            return

        self.send_response(200)
        self.send_header("Content-type", "application/json")
        # Важно: разрешаем CORS, чтобы iOS-приложение могло получить доступ к серверу
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        # Кодируем данные в JSON и отправляем
        self.wfile.write(json.dumps(data, ensure_ascii=False).encode('utf-8'))

if __name__ == "__main__":
    PORT = 8000 # Порт, на котором будет запущен сервер

    # Убедимся, что сервер запускается в папке local_music_api
    os.chdir(os.path.dirname(os.path.abspath(__file__)))

    with socketserver.TCPServer(("", PORT), MusicAPIHandler) as httpd:
        print(f"Server running at http://localhost:{PORT}/")
        print(f"Serving static files from '{STATIC_FOLDER}' folder.")
        print("Press Ctrl+C to stop the server.")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("Shutting down the server...")
            httpd.shutdown()
