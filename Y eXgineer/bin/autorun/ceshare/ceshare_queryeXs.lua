function ceshare.enumModules2()
  local m=enumModules()
  local r={}
  
  for i=1,#m do
    r[m[i].Name:lower()]=m[i]
  end
  
  return r
end

function ceshare.QueryProcesseXs(processname, headermd5, updatableOnly)
  local modulelist=ceshare.enumModules2()
  local result=nil
  --local url=ceshare.base..'QueryProcesseXs.php'
  local parameters='processname='..ceshare.url_encode(processname)
  --print(url..'?'..parameters)
  
  if isKeyPressed(VK_CONTROL)==false then  --control lets you get a new script if needed
    local secondaryIdentifierCode=ceshare.secondaryIdentifierCode.Value[processname:lower()]
    if secondaryIdentifierCode and secondaryIdentifierCode~='' then
      local value,param=loadstring(secondaryIdentifierCode)()
      if value and param then
        parameters=parameters..'&secondaryidentifier='..ceshare.url_encode(param)
      end
    end
  end
  
  if updatableOnly then
    parameters=parameters..'&updatableOnly=1';
  end

  
  
  
  --local r=ceshare.getInternet().postURL(url,parameters)
    --local s=xmlParser:ParseXmlText(r)
    s=ceshare.QueryXURL('QueryProcessTables.php', parameters)
    if s then
      if s.eXList then
        --parse the list
        local i
        --if s.eXList.eX then
          --there are results
          result={}
          for i=1, s.eXList:numChildren() do
            local eXEntry=s.eXList:children()[i]
            if eXEntry then
              local entry={}
              entry.ID=tonumber(eXEntry["@ID"])
              entry.Title=eXEntry["@title"]
              entry.HeaderMD5=eXEntry["@headermd5"]
              entry.Owner=eXEntry["@username"]
              entry.LastEditor=eXEntry["@editorname"]
              entry.VersionIndependent=eXEntry["@versionIndependent"]=='1'
              entry.Public=eXEntry["@public"]=='1'
              entry.Rating=tonumber(eXEntry["@ratingtotal"]) or 0
              entry.RatingCount=tonumber(eXEntry["@ratingcount"]) or 0
              entry.AccessCount=tonumber(eXEntry["@accesscount"]) or 0
              entry.LastEditTime=eXEntry["@lastEditTime"]
              entry.FullFileHash=eXEntry["@fullfilehashmd5"]
              entry.SecondaryModuleName=eXEntry["@secondarymodulename"]
              entry.SecondaryFullFileHash=eXEntry["@secondaryfullfilehashmd5"]
              entry.CheckCode=eXEntry["@luaScriptToCheckForMatch"]
              entry.Description=eXEntry["@description"]
              entry.DataType=eXEntry["@datatype"]
              entry.Signed=eXEntry["@signed"]=='1'
              entry.YourRating=tonumber(ceshare.settings.Value['voted'..entry.ID])
              
              entry.Match=1;
              
    --calculate the match
    --versionIndependant with matching header is always 100%
    --versionIndependant with nonmatching header is 80%
    --non versionIndependent with matching header and fullfilehash is 100%
    --non versionIndependent with matching header is 90%
    --non versionIndependant and non matching header is 1%
    
              
              local matchingHeader=string.lower(entry.HeaderMD5)==string.lower(headermd5)
                           
              if entry.VersionIndependent then  
                if matchingHeader then
                  entry.Match=100
                else
                  entry.Match=80
                end                               
              else
                --not versionIndependent
                if matchingHeader then                 
                  if entry.FullFileHash and entry.FullFileHash~='' then
                    local me=modulelist[processname:lower()]
                    if me then
                      if not me.md5 then
                        me.md5=md5file(me.PathToFile)
                      end
                      
                      if me.md5 then                      
                        if me.md5:lower()==entry.FullFileHash:lower() then
                          entry.Match=100
                        else
                          entry.Match=50                          
                        end                      
                      else 
                        entry.Match=0 --file gone...
                      end
                    else
                      entry.Match=0 --the process exe can not be found? Why am I even here?
                    end
                    
                  else
                    entry.Match=100
                  end
                  
                end
                
                if entry.SecondaryModuleName and entry.SecondaryModuleName~='' then
                  local me=modulelist[SecondaryModuleName:lower()]
                  if me then
                    if not me.md5 then
                      me.md5=md5file(me.PathToFile)
                    end 
                    if me.md5 then
                      if me.md5:lower()==entry.SecondaryModuleName:lower() then
                        entry.Match=100
                      else
                        entry.Match=50
                      end  
                    else
                      entry.Match=0
                    end
                  else
                    entry.Match=0 --module not loaded
                  end
                end                
              end
              
              local signedvalue=0;
              if entry.Signed then signedvalue=1 end
                            
              entry.sortscore=entry.Match*1000+signedvalue*10
              if entry.RatingCount>0 then
                entry.sortscore=entry.sortscore+(entry.Rating/(entry.RatingCount*0.9)) --total votes does count as well
              end
              

              table.insert(result, entry)
            end
          end
          
         
        --end
      end
    end


  --Sort the list by Match , Signed, and Score (in that order)
  if result then
    table.sort(result, function(a,b)
      return a.sortscore>b.sortscore
    end)
  end
  
  return result
end



function ceshare.getCurrentProcessHeaderMD5()
  local pid=getOpenedProcessID()
  if (pid) and (pid~=0) then
    local modulelist=enumModules()
    if (modulelist) and (#modulelist>0) then
      local headermd5=md5memory(modulelist[1].Address,4096)
      return headermd5
    end
  end

end

function ceshare.QueryCurrentProcess(updatableOnly)
  local processnamemd5
  local headermd5
  headermd5=ceshare.getCurrentProcessHeaderMD5()

  if headermd5 then
    return ceshare.QueryProcesseXs(process, headermd5, updatableOnly)
  end
end

function ceshare.CheckForeXsClick(s)
  --spawn the eXbrowser
  
  if ceshare.eXBrowserFrm==nil then
    local f=createFormFromFile(ceshare.formpath..'BrowseeXs.FRM')
    f.lblProcessName.Caption=process

    ceshare.eXBrowserFrm=f

    local h=f.lveXs.Canvas.getTextHeight('XXX')*10
    f.lveXs.Constraints.MinHeight=h
    f.pnlDescription.Constraints.MinHeight=h
    
    --configure base state and add events

    ceshare.eXBrowserFrm.lveXs.OnSelectItem=function(sender, listitem, selected)
      if selected and listitem.index then
        local desc=ceshare.CurrentQuery[listitem.index+1].Description
        
        ceshare.eXBrowserFrm.imgDescription.Width=ceshare.eXBrowserFrm.ScrollBox1.ClientWidth
        ceshare.eXBrowserFrm.imgDescription.Height=ceshare.eXBrowserFrm.ScrollBox1.ClientHeight
        
        ceshare.eXBrowserFrm.imgDescription.Picture.Bitmap.Canvas.Brush.Color=0xffffff
        ceshare.eXBrowserFrm.imgDescription.Picture.Bitmap.Width=ceshare.eXBrowserFrm.ScrollBox1.Width
        ceshare.eXBrowserFrm.imgDescription.Picture.Bitmap.Height=ceshare.eXBrowserFrm.ScrollBox1.Height

        ceshare.eXBrowserFrm.imgDescription.Picture.Bitmap.Canvas.fillRect(0,0,ceshare.eXBrowserFrm.ScrollBox1.Width,ceshare.eXBrowserFrm.ScrollBox1.Height)

        local imgrect={Left=0,Top=0,Right=ceshare.eXBrowserFrm.imgDescription.Width, Bottom=ceshare.eXBrowserFrm.imgDescription.Height}

        

        local r=ceshare.eXBrowserFrm.imgDescription.Picture.Bitmap.Canvas.textRect(imgrect,0,0,desc);
        if r then --ce 7.1+ gets the actually needed rect

        else

        end
        
        --[[local rating=ceshare.CurrentQuery[listitem.index+1].YourRating    
        if rating then
          --trigger a refresh
          ceshare.RateStars[rating].img.OnMouseLeave(ceshare.RateStars[rating]) 
        end--]]
      end
      
      ceshare.RateStars[1].img.OnMouseLeave(ceshare.RateStars[1]) 
  

    end
    
    ceshare.eXBrowserFrm.btnLoadTable.OnClick=function(s)
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      if index~=-1 then
        --load the selected table
        local url=ceshare.base..'GetTable.php'
        local parameters='id='..ceshare.CurrentQuery[index+1].ID        
        local eXtable=ceshare.getInternet().postURL(url,parameters) --not an xml result, so don't use QueryXURL
        local eXtabless=createStringStream(eXtable)
        
        if ceshare.ceversion<7.1 then
          while AddressList.Count>0 do
            AddressList[0].destroy()
          end
        end
        
        loadTable(eXtabless)        
        eXtabless.destroy()
      
        ceshare.eXBrowserFrm.close()
        ceshare.LoadedTable=ceshare.CurrentQuery[index+1]
      end
    end
    
    ceshare.eXBrowserFrm.lveXs.OnDblClick=ceshare.eXBrowserFrm.btnLoadTable.OnClick
    ceshare.eXBrowserFrm.miLoad.OnClick=ceshare.eXBrowserFrm.btnLoadTable.OnClick
    
    --create the 'Rate Table' stars
    ceshare.picFullStar=ceshare.eXBrowserFrm.imgStarFilled.Picture
    ceshare.picEmptyStar=ceshare.eXBrowserFrm.imgStarNotFilled.Picture
  
    ceshare.RateStars={}
    
    local currentLeftControl=ceshare.eXBrowserFrm.lblRate
    local i
    for i=1,5 do
      ceshare.RateStars[i]={}
      ceshare.RateStars[i].state=false
      ceshare.RateStars[i].img=createImage(ceshare.eXBrowserFrm.pnlControls)
      ceshare.RateStars[i].img.Stretch=true
      ceshare.RateStars[i].img.Picture=ceshare.picEmptyStar
      ceshare.RateStars[i].img.AnchorSideLeft.Control=currentLeftControl
      ceshare.RateStars[i].img.AnchorSideLeft.Side=asrRight
      ceshare.RateStars[i].img.AnchorSideTop.Control=ceshare.eXBrowserFrm.lblRate
      ceshare.RateStars[i].img.AnchorSideTop.Side=asrCenter
      ceshare.RateStars[i].img.BorderSpacing.Left=4
      
      ceshare.RateStars[i].img.Cursor=-21
      ceshare.RateStars[i].img.Tag=i
      
      ceshare.RateStars[i].img.OnMouseEnter=function(star)
        local i
        local index=star.Tag
        local cindex=ceshare.eXBrowserFrm.lveXs.ItemIndex
        for i=1,5 do                  
          if (i<=index) and (cindex~=-1) then
            ceshare.RateStars[i].img.Picture=ceshare.picFullStar            
          else
            ceshare.RateStars[i].img.Picture=ceshare.picEmptyStar
          end
        end
      end
      
      ceshare.RateStars[i].img.OnMouseLeave=function(star)
        local cindex=ceshare.eXBrowserFrm.lveXs.ItemIndex
        local yourRating
        if cindex~=-1 then
          yourRating=ceshare.CurrentQuery[cindex+1].YourRating or 0        
        else
          yourRating=0
        end
        
        for i=1,5 do  
          if (yourRating>=i) then
            ceshare.RateStars[i].img.Picture=ceshare.picFullStar           
          else
            ceshare.RateStars[i].img.Picture=ceshare.picEmptyStar           
          end
        end
      end
      
      ceshare.RateStars[i].img.OnClick=function(star)
        local index=ceshare.eXBrowserFrm.lveXs.ItemIndex   
        if index~=-1 then
          local eXid=ceshare.CurrentQuery[index+1].ID  
          local rating=star.tag        
          local parameters='id='..eXid
          parameters=parameters..'&rating='..rating
          xml=ceshare.QueryXURL('RateTable.php',parameters)
          if xml then
            --just a cache so the database doesn't have to be asked and shows even when  not logged in
            ceshare.settings.Value['voted'..eXid]=rating
            ceshare.CurrentQuery[index+1].YourRating=rating 
            
            ceshare.RateStars[star.tag].img.OnMouseLeave(ceshare.RateStars[star.tag])
          end
        end        
      end
      
      currentLeftControl=ceshare.RateStars[i].img
    end
    local RateStars={}


    ceshare.eXBrowserFrm.miViewComments.OnClick=function(s)
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      if index~=-1 then
        ceshare.ViewComments(ceshare.CurrentQuery[index+1])
      end
    end
    
    ceshare.eXBrowserFrm.btnAddViewComments.OnClick=ceshare.eXBrowserFrm.miViewComments.OnClick

    ceshare.eXBrowserFrm.miLoginToSeeMoreOptions.OnClick=function(s)
      ceshare.spawnLoginDialog()
    end

    ceshare.eXBrowserFrm.miUpdateTable.OnClick=function(s)
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      if index~=-1 then
        ceshare.PublisheXClick(nil,ceshare.CurrentQuery[index+1])
      end    
    end
    
    ceshare.eXBrowserFrm.miDeleteTable.OnClick=function(s)
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      if index~=-1 then
        ceshare.Delete(entry)
      end    
    end    
    
    ceshare.eXBrowserFrm.miManageAccessList.OnClick=function(s)
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      if index~=-1 then
        local entry=ceshare.CurrentQuery[index+1]
        ceshare.ManageAccessList(entry)
      end
    end
    
    ceshare.eXBrowserFrm.pmList.OnPopup=function(s)
      if ceshare.LoggedIn==nil then ceshare.LoggedIn=false end
      local index=ceshare.eXBrowserFrm.lveXs.ItemIndex
      
      local canUpdate=false
      local canDelete=false
      local canManage=false
      
      if index~=-1 then
        ceshare.eXBrowserFrm.miLoad.Visible=true
        ceshare.eXBrowserFrm.miViewComments.Visible=true
        ceshare.eXBrowserFrm.miViewHistory.Visible=false --to be implemented later true
        ceshare.eXBrowserFrm.sep.Visible=true
        
        local entry=ceshare.CurrentQuery[index+1]
        if ceshare.LoggedIn then
          if (entry.Permissions==nil) or isKeyPressed(VK_CONTROL) then
            ceshare.getPermissions(entry, true) --don't show errors
          end
          
          if entry.Permissions then
            canUpdate=entry.Permissions.canUpdate
            canDelete=entry.Permissions.canDelete
            canManage=entry.Permissions.canManage
          end
        end
      
      else
        ceshare.eXBrowserFrm.miLoad.Visible=false
        ceshare.eXBrowserFrm.miViewComments.Visible=false
        ceshare.eXBrowserFrm.miViewHistory.Visible=false
        ceshare.eXBrowserFrm.sep.Visible=false      
      end
      
      ceshare.eXBrowserFrm.miLoginToSeeMoreOptions.Visible=ceshare.LoggedIn==false

      
      ceshare.eXBrowserFrm.miUpdateTable.Visible=canUpdate
      ceshare.eXBrowserFrm.miDeleteTable.Visible=canDelete
      ceshare.eXBrowserFrm.miManageAccessList.Visible=canManage
      
    end
    
  end

  --get the table list
  ceshare.eXBrowserFrm.lveXs.clear()
  ceshare.CurrentQuery=ceshare.QueryCurrentProcess()

  if ceshare.CurrentQuery==nil or #ceshare.CurrentQuery==0 then
    messageDialog('Sorry, but there are currently no tables for this target. Perhaps you can be the first',mtError,mbOK)
    return
  end

  for i=1,#ceshare.CurrentQuery do
    local versionIndependent=false
  
    local li=ceshare.eXBrowserFrm.lveXs.Items.add()
    li.Caption=ceshare.CurrentQuery[i].Title
    local owner=ceshare.CurrentQuery[i].Owner
    local editor=ceshare.CurrentQuery[i].LastEditor
    if editor==owner then 
      li.SubItems.add(owner)
    else
      li.SubItems.add(editor..' (owner='..owner..')')
    end
      
    if ceshare.CurrentQuery[i].Public then
      li.SubItems.add('     yes     ')
    else
      li.SubItems.add('     ')
    end

    --todo 7.1+: imagelist and stars
    if ceshare.CurrentQuery[i].RatingCount==0 then
      li.SubItems.add('Unrated')
    else
      li.SubItems.add(ceshare.CurrentQuery[i].Rating/ceshare.CurrentQuery[i].RatingCount..' out of 5 ('..ceshare.CurrentQuery[i].RatingCount..' votes)')
    end

    if ceshare.CurrentQuery[i].VersionIndependent then
      li.SubItems.add('      yes      ')
    else
      li.SubItems.add('             ')
    end

    if ceshare.CurrentQuery[i].Signed then
      li.SubItems.add('     yes     ')
    else    
      li.SubItems.add('           ')  --signed
    end


    li.SubItems.add('  '..ceshare.CurrentQuery[i].Match..'%  ')
    
    if ceshare.LoadedTable==tonumber(ceshare.CurrentQuery[i].ID) then
      ceshare.eXBrowserFrm.lveXs.ItemIndex=i-1
      --select
    end

  end
  

  ceshare.eXBrowserFrm.btnViewHistory.Visible=false --later

  ceshare.eXBrowserFrm.show()
  ceshare.eXBrowserFrm.AutoSize=false
  ceshare.eXBrowserFrm.lveXs.Constraints.MinHeight=0
  ceshare.eXBrowserFrm.pnlDescription.Constraints.MinHeight=0
  
  --adjust starsize
  local dim=ceshare.eXBrowserFrm.btnAddViewComments.Height
  for i=1,5 do  
    ceshare.RateStars[i].img.Width=dim
    ceshare.RateStars[i].img.Height=dim
  end
  
  if not ceshare.eXBrowserFrmShownBefore then
    --adjust the size
    local headerwidth=0
    local i
    for i=0,ceshare.eXBrowserFrm.lveXs.Columns.Count-1 do
      local w=ceshare.eXBrowserFrm.lveXs.Columns[i].Width
      local neededw=ceshare.eXBrowserFrm.Canvas.getTextWidth(' '..ceshare.eXBrowserFrm.lveXs.Columns[i].Caption..' ')
      
      if w<neededw then
        ceshare.eXBrowserFrm.lveXs.Columns[i].Autosize=false
        ceshare.eXBrowserFrm.lveXs.Columns[i].Width=neededw
        w=neededw
      end
        
      headerwidth=headerwidth+w    
    end
    
    ceshare.eXBrowserFrm.ClientWidth=headerwidth+10
    ceshare.eXBrowserFrmShownBefore=true
  end

  ceshare.eXBrowserFrm.Position='poScreenCenter'
end

