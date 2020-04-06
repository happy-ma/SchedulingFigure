def createTaskSet(nts, nss) # the number of tasks and segments, respectively
  taskAttribute = %w[Ri ST ET Pi Ti RT DL]
  
  AttributeNumber.times do |i|
    case i
    when Ri, ST, ET
      $entryTaskAttribute[i] = Array.new(nts) do
        Array.new(nss)
      end
    when Pi, Ti, RT, DL
      $entryTaskAttribute[i] = []
    end
  end
  
  $notebook = Tk::Tile::Notebook.new($root) do
    pack(side: :left)
  end
  
  frame = Array.new(nts) do
    TkFrame.new($notebook)
  end
  
  frame.each_index do |fi|
    tabName = "Task " + (fi + 1).to_s
    $notebook.add(frame[fi], text: tabName)
# 1st row
    taskAttribute.each_index do |tai|
      TkLabel.new(frame[fi]) do
        text taskAttribute[tai]
        font :TkTextFont
        relief :sunken
        grid(row: 0, column: tai, padx: EXTERNAL)
      end
    end
# task's data
    [Pi, Ti, RT, DL].each do |i|
      $entryTaskAttribute[i][fi] = TkEntry.new(frame[fi]) do
        width DataWidth
        justify :right
        grid(row: 1, column: i, padx: EXTERNAL)
      end
    end
    
    nss.times do |si|
      [Ri, ST, ET].each do |i|
        $entryTaskAttribute[i][fi][si] = TkEntry.new(frame[fi]) do
          width DataWidth
          justify :right
          grid(row: si + 1, column: i, padx: EXTERNAL)
        end
      end
    end
  end
  
  unless $taskSet.empty?
    $taskSet.each_with_index do |ti, i|
      ti.segment.each_with_index do |se, j|
        [Ri, ST, ET].each do |si|
          $entryTaskAttribute[si][i][j].value = se[si]
        end
      end
      
      $entryTaskAttribute[Pi][i].value = ti.processorID
      $entryTaskAttribute[Ti][i].value = ti.taskID
      $entryTaskAttribute[RT][i].value = ti.releaseTime
      $entryTaskAttribute[DL][i].value = ti.deadline
    end
  end
  
  $menuBar.entryconfigure(MenuFunction, state: :normal)
  
  $menuFile.entryconfigure(SubmenuClose, state: :normal)
  $menuFile.entryconfigure(SubmenuSave, state: :normal)
  $menuFile.entryconfigure(SubmenuSaveAs, state: :normal)
  
  $menuHelp.entryconfigure(SubmenuFullName, state: :normal)
  
  $menuFile.entryconfigure(SubmenuNew, state: :disabled)
  $menuFile.entryconfigure(SubmenuOpen, state: :disabled)
end

def taskSetData
  pi = "" # processor ID
  ti = "" # task ID
  
  ri = "" # resource ID
  st = "" # start time
  et = "" # end time
  duration = []
  
  resetTaskSet
  
  $entryTaskAttribute[Ti].each_index do |i|########to be improved
    pi = $entryTaskAttribute[Pi][i].value
    ti = $entryTaskAttribute[Ti][i].value
    if pi.empty? || ti.empty?
      break
    else
      $taskSet[i] = Task.new(
        pi.to_i,
        ti.to_i,
        $entryTaskAttribute[RT][i].value.to_i,
        $entryTaskAttribute[DL][i].value.to_i
      )
# segment
      $entryTaskAttribute[Ri][i].each_index do |j|
        ri = $entryTaskAttribute[Ri][i][j].value
        st = $entryTaskAttribute[ST][i][j].value
        et = $entryTaskAttribute[ET][i][j].value
        
        if ri.empty? || st.empty? || et.empty?
          break
        else
          ri = "-1" if "-" == ri[0]
          $taskSet[i].segment << [ri.to_i, st.to_i, et.to_i]
        end
      end
      
      $taskSet[i].alternatingSequence
    end
  end
end
