# Desired behavior
documents = client.documents

document = documents.first

document = Document.new(path)
document.upload

client.documents
client.document(uuid:)

p document
document(uuid).upload
document.delete
document.update
document.download
document.highlights
document.move(locaiton)

# Future behavior
folder.contents
folder.highlights
