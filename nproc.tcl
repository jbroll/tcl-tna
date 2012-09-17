
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
#elif __MACH__ 
    int     count ;
    size_t  size=sizeof(count) ;

    if (sysctlbyname("hw.ncpu",&count,&size,NULL,0)) return 1;

    return count;
#elif __linux
    return sysconf(_SC_NPROCESSORS_ONLN);
#else
    return 1;
#endif
}

