# Current behavior

## Authentication
client = Client.new
client.is_auth? => false
client.register_device(one_time_code)
client.is_auth? => true

## View contents on device
documents = client.documents            # Get metadata for all documents
document = client.documents(uuid: uuid) # Get metadata for one document

## Document features
document.download                       # Download the zip file
document.highlights                     # Array of highlights from document

document = RemarkableRuby::Document.new(path_to_pdf)    
document.upload                         # Upload a pdf/epub

document.update(parent: folder_uuid)    # Move a document
document.update(name: new_name)         # Rename a document

document.delete                         # Move doc to trash
document.delete!                        # Delete doc from device

## Folder features
folder = RemarkableRuby::Folder.new(name: "foo", parent: "")
folder.upload                                 # Create a folder

folder.update(name: "new name")               # Rename a folder
folder.update(parent: "...uuid...")           # Move a folder

folder.delete           # Moves folder (and contents) to trash
folder.delete!          # Deletes folder, contents go to the root directory

# Future behavior
folder.contents               # View a folders contents
folder.delete_with_contents   # Delete a folder and all of its contents
folder.highlights
