class Task
# Constants
  PADDING = 5
  CharacterWidth = 8
  JobHeight = 16
  UnitX = 24
  UnitY = JobHeight * 2
  
  YaxisHeadY = PADDING
  
  YgridInitialY = YaxisHeadY + JobHeight
  XgridHeadY = YaxisHeadY + JobHeight
  
  YscaleX = PADDING
  YscaleOffsetX = 11
  XscaleOffsetY = JobHeight / 2
  
  YaxisNameY = YaxisHeadY + XscaleOffsetY
  
  ArrowOffsetY = JobHeight * 3 / 4
  
  Colour = %w[
    white
    SpringGreen
    brown
    blue
    purple
    yellow
    pink
    snow
    orange
    red
    gray
  ] # adjust according to the number of resources
  
  DASH = -1
  STIPPLE = DASH
  DEADLINE = -2
  LAST = -1
  
  BlockedDuration = -1
  NormalExecution = 0
  
# Class Variables
  @@canvasName = nil
  
  @@tasksNumber = 0
  @@yAxisTailY = 0
  
  @@taskNameOffset = 0
  @@previousProcessorID = 0
  @@yAxisX = 0
  @@xGridInitialX = 0
  
  @@maxTime = 0
  @@yGridTailX = 0
  
# Instance Variables
  attr_accessor :row
  attr_accessor :processorID
  attr_accessor :taskID
  attr_accessor :releaseTime
  attr_accessor :deadline
  attr_accessor :segment
  
# Instance Methods
  def initialize(
    pi = 0,
    ti = 0,
    rt = 0,
    dl = 0
  )
    @@tasksNumber += 1
    @row = @@tasksNumber
    
    @processorID = pi
    @taskID = ti
    @releaseTime = rt
    @deadline = dl
    @segment = []
    @name = ""
    @completionTime = 0
  end
  
  def alternatingSequence
# task's name
    @name = "P" + @processorID.to_s + " - T" + @taskID.to_s### + ": ("commented temporarily!!!
    @segment.sort_by! do |se|
      se[ST]
    end
#commented temporarily!!!
#    @segment.each do |se|
#      @name << (se[ET] - se[ST]).to_s + "," if BlockedDuration != se[Ri]
#    end
#    @name[LAST] = ")"
#commented temporarily!!!
    @@taskNameOffset = @name.length if @name.length > @@taskNameOffset
    
# maximum time
    @completionTime = @segment[LAST][ET]
    
    @@maxTime = @completionTime if @completionTime > @@maxTime
    @@maxTime = @deadline if @deadline > @@maxTime
  end
  
  def drawTask
    yScaleY = YaxisHeadY + XscaleOffsetY + UnitY * @row
    
    separatorHeadX = YscaleX
    separatorTailX = @@yAxisX
    separatorY = yScaleY - XscaleOffsetY - JobHeight
    
    upperLeftX = 0
    upperLeftY = YaxisHeadY + UnitY * @row
    lowerRightX = 0
    lowerRightY = upperLeftY + JobHeight
    
    ri = 0
    resourceIdX = 0
    resourceIdY = (upperLeftY + lowerRightY) / 2
    
    rectangle = nil
    
    completionArrowX = @@xGridInitialX + UnitX * @completionTime
    completionArrowTailY = YaxisHeadY + UnitY * @row
    releaseArrowX = @@xGridInitialX + UnitX * @releaseTime
    releaseArrowTailY = completionArrowTailY + JobHeight
    arrowHeadY = completionArrowTailY - ArrowOffsetY
    
    deadlineX = 0
    deadlineHeadY = arrowHeadY
    deadlineTailY = releaseArrowTailY
    
    completeName = @name###intermediate variable is necessary???
    
# task's name
    TkcText.new(@@canvasName, YscaleX, yScaleY) do # Y scale
      text completeName###???
      anchor :w
    end
    
# separator of processor
    if @processorID != @@previousProcessorID
      if 0 != @@previousProcessorID
        TkcLine.new(@@canvasName, separatorHeadX, separatorY, separatorTailX, separatorY) do
          dash "."
          fill Colour[DASH]
        end
      end
      
      @@previousProcessorID = @processorID
    end
    
# segment
    @segment.each do |se|
      upperLeftX = @@xGridInitialX + UnitX * se[ST]
      lowerRightX = @@xGridInitialX + UnitX * se[ET]
      ri = se[Ri]
      
      rectangle = TkcRectangle.new(@@canvasName, upperLeftX, upperLeftY, lowerRightX, lowerRightY) do
        fill Colour[ri]
      end
      
      case ri
      when NormalExecution
      when BlockedDuration
        rectangle.width 0
        rectangle.stipple :gray25
      else
        resourceIdX = (upperLeftX + lowerRightX) / 2
        
        TkcText.new(@@canvasName, resourceIdX, resourceIdY) do
          text ri
          fill Colour[Ri]
        end
      end
    end
    
# arrow
    TkcLine.new(@@canvasName, releaseArrowX, arrowHeadY, releaseArrowX, releaseArrowTailY) do
      arrow :first
    end
=begin
    TkcLine.new(@@canvasName, completionArrowX, arrowHeadY, completionArrowX, completionArrowTailY) do???
      arrow :last
    end
=end
    
# deadline
    if @deadline > 0
      deadlineX = @@xGridInitialX + UnitX * @deadline
      TkcLine.new(@@canvasName, deadlineX, deadlineHeadY, deadlineX, deadlineTailY) do
        fill Colour[DEADLINE]
        width 3
        capstyle :round
      end
    end
  end
  
# Class Methods
  def self.resetClassVariables
    @@tasksNumber = 0
    @@taskNameOffset = 0
    @@previousProcessorID = 0
    @@maxTime = 0
  end
  
  def self.canvasWidth
    @@taskNameOffset *= CharacterWidth
    @@yAxisX = YscaleX + @@taskNameOffset
    @@xGridInitialX = @@yAxisX + UnitX
    @@yGridTailX = @@xGridInitialX + UnitX * @@maxTime
    
    return @@yGridTailX + UnitX + PADDING
  end
  
  def self.canvasHeight
    @@yAxisTailY = YaxisHeadY + UnitY * (@@tasksNumber + 1)
    
    return @@yAxisTailY + XscaleOffsetY + PADDING
  end
  
  def self.coordinate(cn)
    @@canvasName = cn
    
    xAxisY = @@yAxisTailY
    xAxisHeadX = @@yAxisX
    xAxisTailX = @@yGridTailX + UnitX
    
    yGridY = 0
    yGridHeadX = xAxisHeadX
    xGridX = 0
    xGridTailY = @@yAxisTailY
    
    xScaleY = xAxisY + XscaleOffsetY
    xScaleX = 0
    
    yAxisNameX = @@yAxisX - YscaleOffsetX
    xAxisNameY = xScaleY
    xAxisNameX = xAxisTailX
    
    TkcLine.new(@@canvasName, @@yAxisX, YaxisHeadY, @@yAxisX, @@yAxisTailY) do # Y axis
      arrow :first
    end
    TkcLine.new(@@canvasName, xAxisHeadX, xAxisY, xAxisTailX, xAxisY) do # X axis
      arrow :last
    end
    
    for j in 0..@@tasksNumber do
      yGridY = YgridInitialY + UnitY * j
      TkcLine.new(@@canvasName, yGridHeadX, yGridY, @@yGridTailX, yGridY) do # Y grid
        dash "."
        fill Colour[DASH]
      end
    end
    TkcText.new(@@canvasName, yAxisNameX, YaxisNameY) do # Y axis name
      text "Ti"
    end
    
    for i in 0..@@maxTime do
      xGridX = @@xGridInitialX + UnitX * i
      xScaleX = xGridX
      TkcLine.new(@@canvasName, xGridX, XgridHeadY, xGridX, xGridTailY) do # X grid
        dash "."
        fill Colour[DASH]
      end
      TkcText.new(@@canvasName, xScaleX, xScaleY) do # X scale
        text i
      end
    end
    TkcText.new(@@canvasName, xAxisNameX, xAxisNameY) do # X axis name
      text "t"
    end
  end
end
