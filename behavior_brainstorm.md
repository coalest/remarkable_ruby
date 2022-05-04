# Current behavior

## Authentication
client = Client.new
client.is_auth? => false
client.register_device(one_time_code)
client.is_auth? => true

## View contents on device
documents = client.documents            # Array of all documents
document = client.documents(uuid: uuid) # One document

## Document features
document.download                       # Download the zip file
document.highlights                     # Array of highlights from doc
document.delete                         # Move doc to trash
document.delete!                        # Delete doc from device and cloud

document = Document.new(path_to_pdf)    
document.upload                         # Upload a pdf

document.update(parent: folder_uuid)    # Move a file
document.update(name: new_name)         # Rename a file

# Future behavior
folder.contents
folder.highlights
