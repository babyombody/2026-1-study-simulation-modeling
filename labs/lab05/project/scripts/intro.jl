import Pkg
Pkg.activate("/home/dabakharev/work/study/2026-1/2026-1==study-simulation-modeling/2026-1-study-simulation-modeling/labs/lab05/project")
using DrWatson

# Here you may include files from the source directory
include(srcdir("dummy_src_file.jl"))

println(
"""
Currently active project is: $(projectname())

Path of active project: $(projectdir())

Have fun with your new project!

You can help us improve DrWatson by opening
issues on GitHub, submitting feature requests,
or even opening your own Pull Requests!
"""
)
