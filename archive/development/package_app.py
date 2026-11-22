from pathlib import Path
import shutil,plistlib
base=Path('outputs/星港小队.app/Contents')
(base/'MacOS').mkdir(parents=True,exist_ok=True)
(base/'Resources').mkdir(exist_ok=True)
shutil.copy2('work/tools/Godot.app/Contents/MacOS/Godot',base/'MacOS/StarportSquad')
shutil.copy2('outputs/StarportSquad.pck',base/'MacOS/StarportSquad.pck')
plist={'CFBundleName':'星港小队','CFBundleDisplayName':'星港小队 · Starport Squad','CFBundleIdentifier':'games.starportsquad.prototype','CFBundleExecutable':'StarportSquad','CFBundlePackageType':'APPL','CFBundleShortVersionString':'0.1.0','CFBundleVersion':'1','LSMinimumSystemVersion':'11.0','NSHighResolutionCapable':True,'NSSupportsAutomaticGraphicsSwitching':True,'LSApplicationCategoryType':'public.app-category.games'}
with (base/'Info.plist').open('wb') as f:plistlib.dump(plist,f)
(base/'MacOS/StarportSquad').chmod(0o755)
print(base.parent.resolve())
