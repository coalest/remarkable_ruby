# Desired behavior
documents = client.documents

document = documents.first

document = Document.new(path)
document.upload

client.documents
client.document(uuid:)

p document
document.delete
document.update
document.download
document.highlights
document.move(locaiton)

## Moving
document.update(parent: folder_uuid)

## Renaming
document.update(name: new_name)

# Future behavior
folder.contents
folder.highlights
