local function isWindowVisible(winhandle)
  return executeCodeLocal('IsWindowVisible',winhandle)~=0
end

local function getBaseParentFromWindowHandle(winhandle)
  local i=0
  local last=winhandle

  while winhandle and (winhandle~=0) and (i<10000) do
    last=winhandle
    winhandle=getWindow(winhandle, GW_HWNDOWNER)
    i=i+1
  end;

  return last
end

function ceshare.getProcessTitle(pid)
  local w=getWindow(getForegroundWindow(), GW_HWNDFIRST)

  local bases={}

  while w and (w~=0) do
    if getWindowProcessID(w)==pid then
      if isWindowVisible(w) then
        local h=getBaseParentFromWindowHandle(w)
        local c=getWindowCaption(h)
        if isWindowVisible(h) and (c~='') then
          bases[h]=c
        end
      end
    end
    w=getWindow(w,GW_HWNDNEXT)
  end


  for h,n in pairs(bases) do
    return n --just hope for the best...
  end
end

function ceshare.getCurrentProcessTitle()
  return ceshare.getProcessTitle(getOpenedProcessID())
end



function ceshare.Delete(entry)
  if entry then
    local r=ceshare.QueryXURL('DeleteTable.php','id='..entry.ID)  
    if r then
      if ceshare.eXBrowserFrm and ceshare.eXBrowserFrm.Visible then
        ceshare.CheckForeXsClick()
      end
      
      if ceshare.UpdateOrNewFrm and ceshare.UpdateOrNewFrm.Visible then
        ceshare.PublisheXClick()
      end      
      showMessage('Table successfuly deleted') --meanie
    end
  end
end

function ceshare.PublisheX(data,title,processname, headermd5, versionindependent, description, public, fullfilehash, secondarymodulename, secondaryfullfilehashmd5)


  local parameters=''
   
  if (processname==nil) or (processname=='') then
    ceshare.showError('processname is empty')
    return  
  end
  
  if (title==nil) or (title=='') then
    ceshare.showError('title is empty')
    return  
  end

  if (data==nil) or (data=='') then
    ceshare.showError('data is empty')
    return
  end
  
  if (description==nil) or (description=='') then
    ceshare.showError('description is empty')
    return
  end
  


  parameters='data='..ceshare.url_encode(data)
  parameters=parameters..'&title='..ceshare.url_encode(title)
  parameters=parameters..'&processname='..ceshare.url_encode(processname);
  parameters=parameters..'&description='..ceshare.url_encode(description)   
  if headermd5~=nil then parameters=parameters..'&headermd5='..ceshare.url_encode(headermd5) end    
  if public~=nil then parameters=parameters..'&public='..ceshare.url_encode(public) end  
  if versionindependent~=nil then parameters=parameters..'&versionindependent='..ceshare.url_encode(versionindependent) end
  if fullfilehash~=nil then parameters=parameters..'&fullfilehash='..ceshare.url_encode(fullfilehash) end
  if secondarymodulename~=nil then parameters=parameters..'&secondarymodulename='..ceshare.url_encode(secondarymodulename) end
  if secondaryfullfilehashmd5~=nil then parameters=parameters..'&secondaryfullfilehashmd5='..ceshare.url_encode(secondaryfullfilehashmd5) end
 
  if isKeyPressed(VK_CONTROL)==false then  --control lets you get a new script if needed
    local secondaryIdentifierCode=ceshare.secondaryIdentifierCode.Value[processname:lower()]
    if secondaryIdentifierCode and secondaryIdentifierCode~='' then
      local value,param=loadstring(secondaryIdentifierCode)()
      if value and param then
        parameters=parameters..'&secondaryidentifier='..ceshare.url_encode(param)
      end
    end
  end    
  
 
  local r=ceshare.QueryXURL('PublishTable.php',parameters)
  
  if r then
    showMessage('Thank you, your table has been published');
    return true
  end
end

function ceshare.UpdateeX(id,data,title,headermd5, versionindependent, description, public, fullfilehash, secondarymodulename, secondaryfullfilehashmd5)
  local parameters=''
  
  if id==nil then
    ceshare.showError('No id given')
    return
  end
    
  if (title==nil) or (title=='') then
    ceshare.showError('title is empty')
    return  
  end

  if (data==nil) or (data=='') then
    ceshare.showError('data is empty')
    return
  end
  
  if (description==nil) or (description=='') then
    ceshare.showError('description is empty')
    return
  end
  
  if ceshare.LoggedIn==nil then
    if not ceshare.spawnLoginDialog() then 
      return
    end
  end
  

  parameters=parameters..'id='..id
  parameters=parameters..'&data='..ceshare.url_encode(data)
  parameters=parameters..'&title='..ceshare.url_encode(title)
  parameters=parameters..'&description='..ceshare.url_encode(description)   
  if headermd5~=nil then parameters=parameters..'&headermd5='..ceshare.url_encode(headermd5) end    
  if public~=nil then parameters=parameters..'&public='..ceshare.url_encode(public) end  
  if versionindependent~=nil then parameters=parameters..'&versionindependent='..ceshare.url_encode(versionindependent) end
  if fullfilehash~=nil then parameters=parameters..'&fullfilehash='..ceshare.url_encode(fullfilehash) end
  if secondarymodulename~=nil then parameters=parameters..'&secondarymodulename='..ceshare.url_encode(secondarymodulename) end
  if secondaryfullfilehashmd5~=nil then parameters=parameters..'&secondaryfullfilehashmd5='..ceshare.url_encode(secondaryfullfilehashmd5) end
  
  local r=ceshare.QueryXURL('EditTable.php',parameters)
  
  if r then
    showMessage('Thank you, your table has been updated');
    return true
  end

end

function ceshare.PublisheXClick(sender, eXinfo) 
  --if not logged in, log in now
  if ceshare.LoggedIn==nil then
    if not ceshare.spawnLoginDialog() then 
      return
    end
  end
  
  if eXinfo then
    ceshare.publishOrUpdate(eXinfo)  
    return    
  end
  
  --spawn a window that shows all tables with this processname that the current user has modify rights to
 
  if ceshare.UpdateOrNewFrm==nil then
    local f=createFormFromFile(ceshare.formpath..'UpdateOrNew.FRM') 
    
    f.AutoSize=true
    f.AutoSize=false
    
    local h=f.lveXs.Canvas.getTextHeight('XXX')*10
    local hdelta=h-f.lveXs.Height
    
    if hdelta>0 then
      f.height=f.height+hdelta      
    end
    
    local headerwidth=0
    local i
    for i=0,f.lveXs.Columns.Count-1 do
      local w=f.lveXs.Columns[i].Width
      local neededw=f.Canvas.getTextWidth(' '..f.lveXs.Columns[i].Caption..' ')
      if w<neededw then
        f.lveXs.Columns[i].Autosize=false
        f.lveXs.Columns[i].Width=neededw
        w=neededw
      end
      headerwidth=headerwidth+w    
      
    end
    f.ClientWidth=headerwidth+10
    
    f.lveXs.OnDblClick=function(s)
      f.btnChoose.doClick()
    end
    
    f.rbUpdate.OnChange=function(s)
      f.lveXs.Enabled=s.Checked
      f.btnChoose.Caption='Update table'
    end
    
    f.rbPublish.OnChange=function(s)      
      f.btnChoose.Caption='Publish new table'
    end    
   
    f.btnChoose.OnClick=function(s)
      local eXinfo
      
      if f.rbUpdate.checked then
        local itemindex=f.lveXs.ItemIndex
            
        if itemindex==-1 and f.rbUpdate.checked then
          messageDialog('Please select a eXtable to update', mtError, mbOK);
          return
        end
        
        if itemindex<#ceshare.CurrentUpdateQuery then
          eXinfo=ceshare.CurrentUpdateQuery[itemindex+1]                
          ceshare.publishOrUpdate(eXinfo)          
        else
          messageDialog('Invalid background update query list', mtError, mbOK);
        end
      else
        ceshare.publishOrUpdate()
      end     
      
      
      f.hide()
    end;

    
    ceshare.UpdateOrNewFrm=f
  end;
  
  
  
  --get the table list of entries the user can change
  
  ceshare.CurrentUpdateQuery=ceshare.QueryCurrentProcess(true)
  ceshare.UpdateOrNewFrm.rbUpdate.checked=true
  ceshare.UpdateOrNewFrm.rbUpdate.OnChange(ceshare.UpdateOrNewFrm.rbUpdate)
  
  
  if ceshare.CurrentUpdateQuery==nil or #ceshare.CurrentUpdateQuery==0 then
    --skip to publish instantly
    ceshare.UpdateOrNewFrm.rbPublish.Checked=true
    ceshare.UpdateOrNewFrm.btnChoose.doClick()
  else
    ceshare.UpdateOrNewFrm.lveXs.clear()
    local i
    for i=1,#ceshare.CurrentUpdateQuery do 
      local li=ceshare.UpdateOrNewFrm.lveXs.Items.add()
      li.Caption=ceshare.CurrentUpdateQuery[i].Title
      local owner=ceshare.CurrentUpdateQuery[i].Owner
      local editor=ceshare.CurrentUpdateQuery[i].LastEditor
      if editor==owner then 
        li.SubItems.add(owner)
      else
        li.SubItems.add(editor..' (owner:'..owner..')')
      end
      
      if ceshare.CurrentUpdateQuery[i].Public then
        li.SubItems.add('     yes     ')
      else
        li.SubItems.add('     ')
      end
      
      if ceshare.CurrentUpdateQuery[i].VersionIndependent then
        li.SubItems.add('      yes      ')
      else
        li.SubItems.add('             ')
      end 

      if ceshare.CurrentUpdateQuery[i].Signed then
        li.SubItems.add('     yes     ')
      else    
        li.SubItems.add('           ')  --signed
      end
      
      if (ceshare.LoadedTable) and (ceshare.LoadedTable.ID==ceshare.CurrentUpdateQuery[i].ID) then
        --select the table if a table was loaded and you have access to update
        li.Selected=true
        ceshare.UpdateOrNewFrm.lveXs.ItemIndex=li.Index
      end         
    end
    ceshare.UpdateOrNewFrm.show()    
  end
  
end

function ceshare.publishOrUpdate(eXinfo) --eXinfo is a set if an update
  if ceshare.PublisheXFrm==nil then
    ceshare.PublisheXFrm=createFormFromFile(ceshare.formpath..'PublisheX.frm')    
    --configure base state and add events
    
    
    ceshare.PublisheXFrm.cbVersionIndependent.OnChange=function(s)
      ceshare.PublisheXFrm.lblHeaderMD5Text.visible=true --not s.Checked
      ceshare.PublisheXFrm.lblHeaderMD5.visible=true --not s.Checked
      ceshare.PublisheXFrm.pnlFullFileHash.visible=not s.Checked
      ceshare.PublisheXFrm.cbUseSecondaryModule.visible=not s.checked
      if s.checked then      
        ceshare.PublisheXFrm.cbUseSecondaryModule.checked=false
        ceshare.PublisheXFrm.cbNeedsFullFileHash.checked=false      
      end
    end
    
    
    
    ceshare.PublisheXFrm.cbNeedsFullFileHash.OnChange=function(s)
      local ml=enumModules()
      ceshare.PublisheXFrm.lblFullHeaderMD5Text.visible=s.Checked
      ceshare.PublisheXFrm.lblFullHeaderMD5.visible=s.Checked
      ceshare.PublisheXFrm.lblFullHeaderMD5.Caption=md5file(ml[1].PathToFile)
    end
    
    ceshare.PublisheXFrm.cbUseSecondaryModule.OnChange=function(s)
      --when the 'Use secondary module' checkbox is ticked
      ceshare.PublisheXFrm.lblModulename.visible=s.checked
      ceshare.PublisheXFrm.cbModuleName.visible=s.checked      
      ceshare.PublisheXFrm.pnlModuleFullHash.visible=s.checked
    end
    
    ceshare.PublisheXFrm.cbModuleNeedsFullFileHash.OnChange=function(s)
      ceshare.PublisheXFrm.lblFullModuleHeaderMD5Text.visible=s.checked
      ceshare.PublisheXFrm.lblFullModuleHeaderMD5.visible=s.checked
      
      if s.checked then
        ceshare.PublisheXFrm.cbModuleName.OnChange(s)
      end
    end
    
    ceshare.PublisheXFrm.cbModuleName.OnChange=function(s)
      if ceshare.PublisheXFrm.cbModuleNeedsFullFileHash.Checked then      
        if ceshare.PublisheXFrm.cbModuleName.Text=='' then
          ceshare.PublisheXFrm.lblFullModuleHeaderMD5.caption='<Select a module>'
        else
          local ml=enumModules()
          for i=1,#ml do
            if ml[i].Name:lower()==ceshare.PublisheXFrm.cbModuleName.Text:lower() then
              ceshare.PublisheXFrm.lblFullModuleHeaderMD5.caption=md5file(ml[i].PathToFile)
              ceshare.PublisheXFrm.lblFullModuleHeaderMD5.Font.Color=ceshare.PublisheXFrm.cbModuleNeedsFullFileHash.Font.Color            
              ceshare.PublisheXFrm.cbModuleName.Font.Color=ceshare.PublisheXFrm.cbModuleNeedsFullFileHash.Font.Color            
              return
            end
          end

          ceshare.PublisheXFrm.lblFullModuleHeaderMD5.Caption='<Module not found>'
          ceshare.PublisheXFrm.lblFullModuleHeaderMD5.Font.Color=0x0000ff
          ceshare.PublisheXFrm.cbModuleName.Font.Color=0x0000ff    
        end 
      end      
       
    end
    
    
    
    ceshare.PublisheXFrm.btnCancel.OnClick=function(s)
      ceshare.PublisheXFrm.close()    
    end
   
    ceshare.PublisheXFrm.lblHeaderMD5Text.visible=false
    ceshare.PublisheXFrm.lblHeaderMD5.visible=false
    ceshare.PublisheXFrm.pnlFullFileHash.visible=false    
    ceshare.PublisheXFrm.lblFullHeaderMD5Text.visible=false
    ceshare.PublisheXFrm.lblFullHeaderMD5.visible=false

    ceshare.PublisheXFrm.lblModulename.visible=false
    ceshare.PublisheXFrm.cbModuleName.visible=false

    ceshare.PublisheXFrm.pnlModuleFullHash.visible=false
    ceshare.PublisheXFrm.lblFullModuleHeaderMD5Text.visible=false
    ceshare.PublisheXFrm.lblFullModuleHeaderMD5.visible=false    

    ceshare.PublisheXFrm.cbPublic.checked=false

    ceshare.Position='poScreenCenter'
    
    --position and size saving
    ceshare.PublisheXFrm.OnDestroy=function(s)
      ceshare.settings.Value['PublisheXFrm.x']=s.left
      ceshare.settings.Value['PublisheXFrm.y']=s.top
      ceshare.settings.Value['PublisheXFrm.width']=s.width
      ceshare.settings.Value['PublisheXFrm.height']=s.height
    end
    
    
    local newx=ceshare.settings.Value['PublisheXFrm.x']
    local newy=ceshare.settings.Value['PublisheXFrm.y']
    local newwidth=ceshare.settings.Value['PublisheXFrm.width']
    local newheight=ceshare.settings.Value['PublisheXFrm.height']
    
    if (newwidth~='') or (newheight~='') then
      ceshare.PublisheXFrm.AutoSize=false
    end
    
    if newx~='' then ceshare.PublisheXFrm.Left=newx end
    if newy~='' then ceshare.PublisheXFrm.Top=newy end
    if newwidth~='' then ceshare.PublisheXFrm.Width=newwidth end
    if newheight~='' then ceshare.PublisheXFrm.Height=newheight end    
    
    ceshare.PublisheXFrm.lblFullModuleHeaderMD5.caption=''
    ceshare.PublisheXFrm.lblFullHeaderMD5.Caption=''
  end
  
  ceshare.PublisheXFrm.btnPublish.OnClick=function(sender)   
    if ceshare.PublisheXFrm.cbUseSecondaryModule.Checked then
      if ceshare.PublisheXFrm.cbModuleName.Text=='' then
        messageDialog('Missing module',mtError,mbOK)
        return
      end    
    end
    
    if (AddressList.Count==0) and 
       (getApplication().AdvancedOptions.CodeList2.Items.Count==0) and
       (getApplication().Comments.Memo1.Lines.Count==0) then
      if messageDialog('This looks like an empty table. Are you sure?',mtWarning,mbYes,mbNo)~=mrYes then return end
    end

    if ceshare.PublisheXFrm.cbPublic.Enabled and ceshare.PublisheXFrm.cbPublic.Checked then
      if messageDialog('Are you sure you wish to let \'Everyone\' overwrite your table in the ceshare system ?',mtWarning,mbYes,mbNo)~=mrYes then return end
    end
       
    local temptablepath=ceshare.path..'temptable.ct'
    saveTable(temptablepath)
    
    if MainForm.miSignTable.Visible then
      if messageDialog('Do you wish to sign this table?',mtConfirmation,mbYes,mbNo)==mrYes then
        local originalFile=MainForm.OpenDialog1.FileName
        local originalDir=MainForm.OpenDialog1.InitialDir
        MainForm.OpenDialog1.FileName=ceshare.path..'temptable.ct'
        MainForm.OpenDialog1.InitialDir=ceshare.path
        MainForm.miSignTable.doClick()
        
        MainForm.OpenDialog1.InitialDir=originalDir
        MainForm.OpenDialog1.FileName=originalFile
      end
    end    
    
    local s=createStringList()
    s.loadFromFile(temptablepath)
    
        
    local fullfilehash,secondarymodulename,secondaryfullfilehash
    
    if ceshare.PublisheXFrm.cbNeedsFullFileHash.Checked then
      fullfilehash=ceshare.PublisheXFrm.lblFullHeaderMD5.Caption
    end
    
    if ceshare.PublisheXFrm.cbUseSecondaryModule.Checked then
      secondarymodulename=ceshare.PublisheXFrm.cbModuleName.Text 
      secondaryfullfilehash=ceshare.PublisheXFrm.lblFullModuleHeaderMD5.caption
    end
    

    

    if eXinfo then
      if ceshare.UpdateeX(eXinfo.ID,
                            s.Text, --data
                            ceshare.PublisheXFrm.edtTitle.Text,                              
                            ceshare.PublisheXFrm.lblHeaderMD5.Caption, --headermd5
                            ceshare.PublisheXFrm.cbVersionIndependent.checked, --versionindependent
                            ceshare.PublisheXFrm.mDescription.Lines.Text, --description
                            ceshare.PublisheXFrm.cbPublic.Checked,                                
                            fullfilehash,
                            secondarymodulename,
                            secondaryfullfilehash) then
        ceshare.PublisheXFrm.close() 
      end          
    else
      if ceshare.PublisheX(s.Text, --data
                            ceshare.PublisheXFrm.edtTitle.Text,
                            ceshare.PublisheXFrm.edtProcessName.Text, --processname
                            ceshare.PublisheXFrm.lblHeaderMD5.Caption, --headermd5
                            ceshare.PublisheXFrm.cbVersionIndependent.checked, --versionindependent
                            ceshare.PublisheXFrm.mDescription.Lines.Text, --description
                            ceshare.PublisheXFrm.cbPublic.Checked,                                
                            fullfilehash,
                            secondarymodulename,
                            secondaryfullfilehash) then
        ceshare.PublisheXFrm.close()                            
      end
    end
       
    s.destroy()
  
  end      

  
  
  --fill in header and processname
  local headermd5
  headermd5=ceshare.getCurrentProcessHeaderMD5()
  
  local ml=enumModules()
  
  ceshare.PublisheXFrm.cbModuleName.Items.clear()
  for i=1,#ml do    
    ceshare.PublisheXFrm.cbModuleName.Items.add(ml[i].Name)
  end


      
  if eXinfo then
    ceshare.PublisheXFrm.Caption='Update table'
    ceshare.PublisheXFrm.edtTitle.Text=eXinfo.Title
    
    if eXinfo.public then
      ceshare.PublisheXFrm.cbPublic.checked=true
      ceshare.PublisheXFrm.cbPublic.enabled=false
    else
      ceshare.PublisheXFrm.cbPublic.checked=false
      ceshare.PublisheXFrm.cbPublic.enabled=true    
    end    
  else
    ceshare.PublisheXFrm.cbPublic.checked=false
    ceshare.PublisheXFrm.cbPublic.enabled=true
  
    ceshare.PublisheXFrm.Caption='Publish new table'
    local pt=ceshare.getCurrentProcessTitle()
    if pt then
      ceshare.PublisheXFrm.edtTitle.Text=pt
    end
  end

  ceshare.PublisheXFrm.edtProcessName.text=process
  ceshare.PublisheXFrm.edtProcessName.Enabled=eXinfo==nil
  ceshare.PublisheXFrm.cbPublic.Enabled=(eXinfo==nil) or (eXinfo.Public==false)
  if eXinfo then
    ceshare.PublisheXFrm.mDescription.Lines.Text=eXinfo.Description
    ceshare.PublisheXFrm.cbVersionIndependent.Checked=eXinfo.VersionIndependent
    ceshare.PublisheXFrm.cbPublic.Checked=eXinfo.Public
    
    ceshare.PublisheXFrm.cbNeedsFullFileHash.Checked=(eXinfo.FullFileHash~=nil) and (eXinfo.FullFileHash~='')
    ceshare.PublisheXFrm.cbUseSecondaryModule.Checked=(eXinfo.SecondaryModuleName~=nil) and (eXinfo.SecondaryModuleName~='')
    ceshare.PublisheXFrm.cbModuleName.Text=eXinfo.SecondaryModuleName     
    ceshare.PublisheXFrm.cbModuleName.OnChange(ceshare.PublisheXFrm.cbModuleName)
    
    ceshare.PublisheXFrm.cbVersionIndependent.Checked=eXinfo.VersionIndependent
   
  end
  ceshare.PublisheXFrm.cbVersionIndependent.OnChange(ceshare.PublisheXFrm.cbVersionIndependent)  
 
  if headermd5==nil then
    ceshare.PublisheXFrm.lblHeaderMD5.Caption=''
    ceshare.PublisheXFrm.cbNeedsFullFileHash.enabled=false    
  else
    ceshare.PublisheXFrm.lblHeaderMD5.Caption=headermd5
    ceshare.PublisheXFrm.cbNeedsFullFileHash.enabled=true
  end

  ceshare.PublisheXFrm.show() --clicking publish will do the rest
end
