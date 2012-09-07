
package provide nproc 0.5

critcl::ccode {
    #ifdef _WIN32
    #include <windows.h>
    #elif MACOS
    #include <sys/param.h>
    #include <sys/sysctl.h>
    #else
    #include <unistd.h>
    #endif
}
 
critcl::cproc nproc {} int {
#ifdef WIN32
    SYSTEM_INFO sysinfo;
    GetSystemInfo(&sysinfo);
    return sysinfo.dwNumberOfProcessors;
#elif MACOS
    int nm[2];
    size_t len = 4;
    uint32_t count;
 
    nm[0] = CTL_HW; nm[1] = HW_AVAILCPU;
    sysctl(nm, 2, &count, &len, NULL, 0);
 
    if(count < 1) {
    nm[1] = HW_NCPU;
    sysctl(nm, 2, &count, &len, NULL, 0);
    if(count < 1) { count = 1; }
    }
    return count;
#elif __linux
    return sysconf(_SC_NPROCESSORS_ONLN);
#else
    return 1;
#endif
}

