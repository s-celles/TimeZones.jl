module TimeZones

using Artifacts: Artifacts
using Dates
using Printf
using Scratch: @get_scratch!
using Unicode
using InlineStrings: InlineString15
using TZJData: TZJData

import Dates: TimeZone, UTC

export TimeZone, @tz_str, istimezone, FixedTimeZone, VariableTimeZone, ZonedDateTime,
    DateTime, Date, Time, UTC, Local, TimeError, AmbiguousTimeError, NonExistentTimeError,
    UnhandledTimeError, TZFile,
    # discovery.jl
    timezone_names, all_timezones, timezones_from_abbr, timezone_abbrs,
    next_transition_instant, show_next_transition,
    # accessors.jl
    timezone, hour, minute, second, millisecond,
    # adjusters.jl
    firstdayofweek, lastdayofweek,
    firstdayofmonth, lastdayofmonth,
    firstdayofyear, lastdayofyear,
    firstdayofquarter, lastdayofquarter,
    # Re-export from Dates
    yearmonthday, yearmonth, monthday, year, month, week, day, dayofmonth,
    # conversion.jl
    now, today, todayat, astimezone,
    # local.jl
    localzone,
    # ranges.jl
    guess

_scratch_dir() = @get_scratch!("build")

const _COMPILED_DIR = Ref{String}()

# TimeZone types used to disambiguate the context of a DateTime
# abstract type UTC <: TimeZone end  # Already defined in the Dates stdlib
abstract type Local <: TimeZone end

function __init__()
    # Set at runtime to ensure relocatability
    _COMPILED_DIR[] = @static if isdefined(TZJData, :artifact_dir)
        TZJData.artifact_dir()
    else
        # Backwards compatibility for TZJData versions below v1.3.1. The portion of the
        # code which determines the `pkg_dir` could be replaced by `pkgdir(TZJData)` however
        # the `pkgdir` function doesn't work well with relocated system images.
        pkg = Base.identify_package(TZJData, "TZJData")
        pkg_dir = dirname(dirname(Base.locate_package(pkg)))
        artifact_dict = Artifacts.parse_toml(joinpath(pkg_dir, "Artifacts.toml"))
        hash = Base.SHA1(artifact_dict["tzjdata"]["git-tree-sha1"])
        Artifacts.artifact_path(hash)
    end

    # Dates extension needs to happen everytime the module is loaded (issue #24)
    init_dates_extension()

    if haskey(ENV, "JULIA_TZ_VERSION")
        @info "Using tzdata $(TZData.tzdata_version())"
    end
end

include("utils.jl")
include("indexable_generator.jl")

include("class.jl")
include("utcoffset.jl")
include(joinpath("types", "timezone.jl"))
include(joinpath("types", "fixedtimezone.jl"))
include(joinpath("types", "variabletimezone.jl"))
include(joinpath("types", "timezonecache.jl"))
include(joinpath("types", "zoneddatetime.jl"))
include(joinpath("tzfile", "TZFile.jl"))
include(joinpath("tzjfile", "TZJFile.jl"))
include("exceptions.jl")
include(joinpath("tzdata", "TZData.jl"))
include("windows_zones.jl")
include("build.jl")
include("interpret.jl")
include("accessors.jl")
include("arithmetic.jl")
include("io.jl")
include("adjusters.jl")
include("conversions.jl")
include("local.jl")
include("ranges.jl")
include("discovery.jl")
include("rounding.jl")
include("parse.jl")
include("deprecated.jl")

# Required to support Julia `VERSION < v"1.9"`
if !isdefined(Base, :get_extension)
    include("../ext/TimeZonesRecipesBaseExt.jl")
end

end # module
