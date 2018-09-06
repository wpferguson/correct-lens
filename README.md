# correct_lens

**correct_lens.lua** provides a non-destructive way to correct the lens information used by darktable during image processing.

When darktable imports an image it extracts certain information, including the lens identification string, from the image and inserts it into the library database.  That database field is what darktable uses to display lens information and what the lens correction module uses to determine what correction to apply.  If we update that field to the correct lens string, as used by lensfun, then the lens correction module applies the correct correction and the image display module displays the correct information.

**correct_lens.lua** essentially builds a lookup table to translate from what the camera thinks the lens is, to what it actually is.  Once you've identified your lenses and the correct translation, then all that's left is to apply it to the images that need it.  

I shoot with a Canon EOS 7D.  I have a Sigma 17-50mm f/2.8 lens.  When I take a picture the exif data shows that I used a Canon EF-S 17-55mm f/2.8 IS USM.  I also have a Sigma 50-100mm f/1.8 Art lens.  The images identify it as Canon EF 28mm f/1.8 USM.  To fix this I install correct_lens.lua in my lua-scripts and enable it.  I go to a directory, or directories, with the mis-identified lenses and select an image or images.  In the correct lens module I click the detect button.  The detected lenses appear in the text box.  After this I restart darktable so that I can add the corrected strings.  Once darktable is restarted I go the the correct lens module and select the lens I want to change from the drop down list.  I enter the lens string from the lensfun database for my lens.  In the case of the 17-50mm it's Sigma 17-50mm f/2.8 EX DC OS HSM. Once I've entered it I click save to add it to the translation table.  If I accidently save a bad translation, I can select it from the drop down and hit clear to remove it.  Once I've got my lens correction strings entered, I go to a folder with mis-identified lenses.  I select the images and either click the apply button in the correct lens module or click the correct lens information button in the selected images module.  _correct_lens.lua_ will check each selected image for the offending lens string(s) and replace them if it's found.  If the string is not found, or there is no corrected string, the lens information for the image remains unchanged.  A tag is added to the image noting what the original lens information was.  This is in case you want to revert the changes.  This can be done by selecting the image(s) and clicking the revert button in the correct lens module.

**correct_lens.lua** is **SLOW**.  On my system it processes approximately 2 changed images per second.  This is because it's writing each change to the database.  In addition, if you change lots of images, darktable will take a while to shut down when you end it because it has to update the xmp files with the tags.  I changed 1000-1500 images and darktable took a couple of minutes to shut down.

I'm putting this out for testing.  I wrote it in response to the threads in the mailing list about mis-identified lenses and the ensuing discussing about modifying the original images. This works for me and does what I need it to.  Others may need further features or changes I didn't think of.  Once I get it all ironed out, I'll add it to the lua-scripts repository.

## Installation

If you're using script_manager, add it to your downloads directory and enable it.

Otherwise, cd to your lua directory and do a git clone https://github.com/wpferguson/correct-lens.  Then edit your luarc file and include the line
  require "correct-lens/correct_lens"

_correct_lens.lua_ relies on the lua-scripts libraries, so it's recommended that you have the full lua-scripts repository installed.

## Usage

Select images with mis-identified lenses, then click the detect button in the correct lens module.  Restart darktable.  Select each lens that needs the string corrected from the drop down.  Add the lens string for your lens as used in the lensfun database, then click save.  Select the images you want to update and click apply.

If for some reason you need to go back to the original information, select the images and click revert.

## Notes

It's **SLOW**.  I average 2 images per second.  I have a fast processor, lots of memory and an SSD.  Your performance might be worse.

Problems, ideas, etc., e-mail me at wpferguson@gmail.com