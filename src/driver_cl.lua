
----- cl compiler ------
function compile_c_cxx_cl(cpp, label, output, input, settings)
	local defs = tbl_to_str(settings.cc.defines, "-D", " ") .. " "
	local incs = tbl_to_str(settings.cc.includes, '-I"', '" ')
	local incs = incs .. tbl_to_str(settings.cc.systemincludes, '-I"', '" ')
	local flags = settings.cc.flags:ToString()
	if cpp == "c++" then
		flags = flags .. settings.cc.cpp_flags:ToString()
	else
		flags = flags .. settings.cc.c_flags:ToString()
	end
	
	local exe = str_replace(settings.cc.c_exe, "/", "\\")
	if platform =="win32" then
		flags = flags .. " /D \"WIN32\" "
	else
		flags = flags .. " /D \"WIN64\" "
	end
	
	if settings.debug > 0 then flags = flags .. "/Od /MTd /Z7 /D \"_DEBUG\" " end
	if settings.optimize > 0 then flags = flags .. "/Ox /Ot /MT /D \"NDEBUG\" " end
	local exec = exe .. " /nologo /D_CRT_SECURE_NO_DEPRECATE /c " .. flags .. input .. " " .. incs .. defs .. " /Fo" .. output

	AddJob(output, label, exec)
	SetFilter(output, "F" .. PathFilename(input))
end

function DriverCXX_CL(label, output,input, settings)
	compile_c_cxx_cl(true, label, output, input, settings)
end

function DriverC_CL(label, output, input, settings)
	compile_c_cxx_cl(nil, label, output, input, settings)
end

function DriverCTest_CL(code, options)
	local f = io.open("_test.c", "w")
	f:write(code)
	f:write("\n")
	f:close()
	local ret = ExecuteSilent("cl _test.c /Fe_test " .. options)
	os.remove("_test.c")
	os.remove("_test.exe")
	os.remove("_test.obj")
	return ret==0
end

function DriverLib_CL(output, inputs, settings)
	local input =  tbl_to_str(inputs, "", " ")
	local exe = str_replace(settings.lib.exe, "/", "\\")
	local exec = exe .. " /nologo " .. settings.lib.flags:ToString() .. " /OUT:" .. output .. " " .. input
	return exec
end

function DriverCommon_CL(label, output, inputs, settings, part, extra)
	local input =  tbl_to_str(inputs, "", " ")
	local flags = part.flags:ToString()
	local libs  = tbl_to_str(part.libs, "", ".lib ")
	local libpaths = tbl_to_str(part.libpath, "/libpath:\"", "\" ")
	local exe = str_replace(part.exe, "/", "\\")
	if settings.debug > 0 then flags = flags .. "/DEBUG " end
	local exec = exe .. " /nologo /incremental:no " .. extra .. " " .. flags .. libpaths .. libs .. " /OUT:" .. output .. " " .. input
	AddJob(output, label, exec)
end

function DriverDLL_CL(label, output, inputs, settings)
	DriverCommon_CL(label, output, inputs, settings, settings.dll, "/DLL")
	local libfile = string.sub(output, 0, string.len(output) - string.len(settings.dll.extension)) .. settings.lib.extension
	AddOutput(output, libfile)
end

function DriverLink_CL(label, output, inputs, settings)
	DriverCommon_CL(label, output, inputs, settings, settings.dll, "")
end

function SetDriversCL(settings)
	if settings.cc then
		settings.cc.extension = ".obj"
		settings.cc.c_exe = "cl"
		settings.cc.cxx_exe = "cl"
		settings.cc.DriverCTest = DriverCTest_CL
		settings.cc.DriverC = DriverC_CL
		settings.cc.DriverCXX = DriverCXX_CL	
	end
	
	if settings.link then
		settings.link.extension = ".exe"
		settings.link.exe = "link"
		settings.link.Driver = DriverLink_CL
	end
	
	if settings.lib then
		settings.lib.extension = ".lib"
		settings.lib.exe = "lib"
		settings.lib.Driver = DriverLib_CL
	end
	
	if settings.dll then
		settings.dll.extension = ".dll"
		settings.dll.exe = "link"
		settings.dll.Driver = DriverDLL_CL
	end
end