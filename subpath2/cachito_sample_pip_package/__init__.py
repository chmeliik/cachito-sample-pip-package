import requests

r = requests.get("https://raw.githubusercontent.com/release-engineering/cachito/master/README.md")

print(r.text)
