require "tk"

require "./sfWidget.rb"
require "./sfTask.rb"

# Constants
FontSize = 15

MenuFile = "File"
SubmenuNew = "New"
SubsubmenuTaskSet = "Task Set"
SubsubmenuOthers = "Others ..."
SubmenuOpen = "Open ..."
SubmenuClose = "Close"
SubmenuSave = "Save"
SubmenuSaveAs = "Save as ..."
SubmenuExit = "Exit"

MenuFunction = "Function"
SubmenuDraw = "Draw"
SubmenuClear = "Clear"

MenuHelp = "Help"
SubmenuFullName = "Full Name"
SubmenuAbout = "About"

ATTRIBUTE = 0
VALUE = 1

FileType = "TS Files"
DefaultExtension = ".ts"
DefaultDirectory = "./example" + DefaultExtension

Ri = 0
ST = Ri + 1
ET = ST + 1
Pi = ET + 1
Ti = Pi + 1
RT = Ti + 1
DL = RT + 1
AttributeNumber = DL + 1

DataWidth = 2
EXTERNAL = 8

# Global Variables
$root = TkRoot.new

$menuBar = nil
$menuFile = nil
$menuFunction = nil
$submenuNew = nil
$menuHelp = nil

$entryTaskAttribute = []
$notebook = nil
$canvas = nil

$taskSet = []

$isOpen = false

# Message Boxes
def mbInputData
  Tk.messageBox(
    icon: :warning,
    message: "Please input tasks' data correctly!"
  )
end

def mbAbbreviations
  Tk.messageBox(
    title: "Abbreviations",
    message:
      "Ri: resource ID\n" +
      "ST: start time\n" +
      "ET: end time\n" +
      "Pi: processor ID\n" +
      "Ti: task ID\n" +
      "RT: release time\n" +
      "DL: deadline"
  )
end

def mbMadeBy
  Tk.messageBox(message: "Made by Happy-MA")
end

# Methods
def resetTaskSet
  $taskSet = []
  Task.resetClassVariables
end

# Procedures
def procNewTaskSet
  windowNumbers = TkToplevel.new($root) do
    title "Numbers"
  end
  
  TkLabel.new(windowNumbers) do
    text "How many tasks are there in the task set? "
    font :TkTextFont
    relief :sunken
    grid(row: 0, column: 0)
  end
  
  entryTaskNumber = TkEntry.new(windowNumbers) do
    width 2
    relief :sunken
    grid(row: 0, column: 1)
  end
  entryTaskNumber.value = 8 # default
  
  TkLabel.new(windowNumbers) do
    text "How many segments are there in each task? "
    font :TkTextFont
    relief :sunken
    grid(row: 1, column: 0)
  end
  
  entrySegmentNumber = TkEntry.new(windowNumbers) do
    width 2
    relief :sunken
    grid(row: 1, column: 1)
  end
  entrySegmentNumber.value = 8 # default
  
  TkButton.new(windowNumbers) do
    text "Create"
    font :TkTextFont
    grid(row: 2, column: 0, columnspan: 2)
    command proc {
      createTaskSet(entryTaskNumber.value.to_i, entrySegmentNumber.value.to_i)
      windowNumbers.destroy
    }
  end
end

def procOpen
  i = 0
  n = 0
  
  data = []
  line = []
  lvi = 0
  
  ti = nil
  nss = 0 # the number of segments
  se = [] # segment
  
  directory = Tk.getOpenFile(
    filetypes: [
      [FileType, DefaultExtension]
    ]
  )
  
  unless directory.empty?
    data = File.readlines(directory)
    n = data.size
    
    while i < n
      line = data[i].chomp.split(/:/)
      lvi = line[VALUE].to_i
      
      case line[ATTRIBUTE]
      when "Task"
        ti = Task.new
      when "processorID"
        ti.processorID = lvi
      when "taskID"
        ti.taskID = lvi
      when "releaseTime"
        ti.releaseTime = lvi
      when "deadline"
        ti.deadline = lvi
      when "segment"
        nss = lvi if lvi > nss
        
        lvi.times do
          se = data[i + 1].split
          ti.segment << [se[Ri].to_i, se[ST].to_i, se[ET].to_i]
          i += 1
        end
        ti.alternatingSequence
        $taskSet << ti
      end
      
      i += 1
    end
    
    $isOpen = true
    
    createTaskSet($taskSet.size, nss)
    procDraw
  end
end

def procClose
  if $canvas
    $canvas.destroy
    $canvas = nil
  end
  $notebook.destroy
  
  $menuBar.entryconfigure(MenuFunction, state: :disabled)
  
  $menuFile.entryconfigure(SubmenuClose, state: :disabled)
  $menuFile.entryconfigure(SubmenuSave, state: :disabled)
  $menuFile.entryconfigure(SubmenuSaveAs, state: :disabled)
  
  $menuHelp.entryconfigure(SubmenuFullName, state: :disabled)
  
  $menuFile.entryconfigure(SubmenuNew, state: :normal)
  $menuFile.entryconfigure(SubmenuOpen, state: :normal)
  
  resetTaskSet
end

def procSave(directory = DefaultDirectory)
  unless directory.empty?
    taskSetData
    
    if $taskSet.empty?
      mbInputData
    else
      File.open(directory, "w") do |io|
        $taskSet.each do |ti|
          io.print "Task:"
          io.puts ti.row
          io.print "processorID:"
          io.puts ti.processorID
          io.print "taskID:"
          io.puts ti.taskID
          io.print "releaseTime:"
          io.puts ti.releaseTime
          io.print "deadline:"
          io.puts ti.deadline
          io.print "segment:"
          io.puts ti.segment.size
          ti.segment.each do |seg|
            seg.each do |se|
              io.print se, "\t"
            end
            io.puts
          end
        end
      end
    end
  end
end

def procSaveAs
  procSave(
    Tk.getSaveFile(
      defaultextension: DefaultExtension,
      filetypes: [
        [FileType, DefaultExtension]
      ]
    )
  )
end

def procDraw
  taskSetData unless $isOpen
  
  if $taskSet.empty?
    mbInputData
  else
    if $canvas
      $canvas.delete :all
    else
      $canvas = TkCanvas.new($root) do
        background :white
        pack(side: :right)
      end
    end
    
    $canvas.width = Task.canvasWidth
    $canvas.height = Task.canvasHeight
    Task.coordinate($canvas)
    $taskSet.each do |ti|
      ti.drawTask
    end
    
    $isOpen = false
  end
end

def procClear
  $entryTaskAttribute.each_with_index do |eta, i|
    case i
    when Ri, ST, ET
      eta.each do |ta|
        ta.each do |t|
          t.value = ""
        end
      end
    when Pi, Ti, RT, DL
      eta.each do |ta|
        ta.value = ""
      end
    end
  end
end

# Configure
TkFont.configure(
  :TkMenuFont,
  size: FontSize
)

TkFont.configure(
  :TkTextFont,
  size: FontSize
)

Tk::Tile::Style.configure("TNotebook.Tab", font: :TkMenuFont)

TkOption.add("*tearOff", 0) # remove dashed lines in the menus

# Menus
$submenuNew = TkMenu.new do
  add(
    :command,
    label: SubsubmenuTaskSet,
    underline: 0,
    command: proc {procNewTaskSet}
  )
  
  add(
    :command,
    label: SubsubmenuOthers,
    underline: 0,
    command: proc {puts "Test Submenu: Other ..."}
  )
end

$menuFile = TkMenu.new do
  add(
    :cascade,
    menu: $submenuNew,
    label: SubmenuNew,
    underline: 0
  )
  
  add(
    :command,
    label: SubmenuOpen,
    underline: 0,
    command: proc {procOpen}
  )
  
  add(
    :command,
    label: SubmenuClose,
    underline: 0,
    state: :disabled,
    command: proc {procClose}
  )
  
  add :separator
  
  add(
    :command,
    label: SubmenuSave,
    underline: 0,
    state: :disabled,
    command: proc {procSave}
  )
  
  add(
    :command,
    label: SubmenuSaveAs,
    underline: 1,
    state: :disabled,
    command: proc {procSaveAs}
  )
  
  add :separator
  
  add(
    :command,
    label: SubmenuExit,
    underline: 1,
    command: proc {exit}
  )
end

$menuFunction = TkMenu.new do
  add(
    :command,
    label: SubmenuDraw,
    underline: 0,
    command: proc {procDraw}
  )
  
  add(
    :command,
    label: SubmenuClear,
    underline: 0,
    command: proc {procClear}
  )
end

$menuHelp = TkMenu.new do
  add(
    :command,
    label: SubmenuFullName,
    underline: 0,
    state: :disabled,
    command: proc {mbAbbreviations}
  )
  
  add :separator
  
  add(
    :command,
    label: SubmenuAbout,
    underline: 0,
    command: proc {mbMadeBy}
  )
end

$menuBar = TkMenu.new do
  add(
    :cascade,
    menu: $menuFile,
    label: MenuFile,
    underline: 0
  )
  
  add(
    :cascade,
    menu: $menuFunction,
    label: MenuFunction,
    underline: 3,
    state: :disabled
  )
  
  add(
    :cascade,
    menu: $menuHelp,
    label: MenuHelp,
    underline: 0
  )
end

# Main
$root.title = "Scheduling"
$root.menu = $menuBar

Tk.mainloop
