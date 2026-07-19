import os
import json


class JsonEdit:
    def __init__(self, file_path):
        self.file = file_path

    def read(self):
        if not os.path.exists(self.file):
            return {}
        with open(self.file, 'r+', encoding='utf-8') as pf:
            try:
                return json.load(pf)
            except (AttributeError, ValueError, json.decoder.JSONDecodeError):
                return {}

    def write(self, data):
        dirname = os.path.dirname(self.file)
        if dirname and not os.path.exists(dirname):
            os.makedirs(dirname, exist_ok=True)
        with open(self.file, 'w+', encoding='utf-8') as pf:
            json.dump(data, pf, indent=4)

    def edit(self, name, value):
        data = self.read()
        data[name] = value
        self.write(data)
