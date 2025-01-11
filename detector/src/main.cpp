#include <type_traits>
#include <print>
#include <cstdint>
#include <concepts>
#if __has_include(<clocale>)
    #include <clocale>
#endif

// all glory to QQ user "anms.." for writing this code
#define SET_PROBE() \
    namespace { auto probe = []{}; decltype(probe) probing_func(); }

#define DETECT_IN(ns, id) \
    namespace ns { \
        namespace { \
            auto id = probe; \
        } \
        namespace id##_helper { \
            constexpr bool result = ::std::is_same_v<decltype(ns :: id), decltype(probe)>; \
        } \
    }
#define DETECT_TYPE_IN(ns, id) \
    namespace ns { \
        namespace { \
            using id = decltype(probe); \
        } \
        namespace id##_helper { \
            constexpr bool result = ::std::is_same_v<ns :: id, decltype(probe)>; \
        } \
    }
#define DETECT_FUNC_IN(ns, id) \
    namespace ns { \
        namespace { \
            decltype(probe) id(); \
        } \
        namespace id##_helper { \
            constexpr bool result = ::std::is_same_v<decltype(ns :: id), decltype(probing_func)>; \
        } \
    }
#define DETECT_GLOBAL(id) DETECT_IN(, id)
#define DETECT_TYPE_GLOBAL(id) DETECT_TYPE_IN(, id)
#define DETECT_FUNC_GLOBAL(id) DETECT_FUNC_IN(, id)

#define IF_EXISTS_IN(ns, id) (!ns :: id##_helper :: result)
#define IF_EXISTS_GLOBAL(id) IF_EXISTS_IN(, id)

SET_PROBE()
DETECT_FUNC_GLOBAL(memset_s)
DETECT_FUNC_GLOBAL(localeconv)
DETECT_TYPE_GLOBAL(lconv)

int main()
{
    constexpr bool have_memset_s = IF_EXISTS_GLOBAL(memset_s);

    constexpr bool have_clocale =
        #if __has_include(<clocale>)
            true;
        #else
            false;
        #endif

    constexpr bool have_localeconv =
        #if __has_include(<clocale>)
            IF_EXISTS_GLOBAL(localeconv);
        #else
            false;
        #endif

    constexpr std::size_t lconv_size = []<typename T = void>()
    {
        if constexpr (IF_EXISTS_GLOBAL(lconv))
            return sizeof(::lconv);
        else
            return 0;
    }();

    constexpr bool have_decimal_point = []<typename T = void>()
    {
        return requires (::lconv c) {
            std::same_as<
                char *,
                std::remove_cvref_t<decltype(c.decimal_point)>
            >;
        };
    }();

    std::print("{{\"have_memset_s\":{},\"have_clocale\":{},\"have_localeconv\":{},\"lconv_size\":{},\"have_decimal_point\":{}}}",
        have_memset_s,
        have_clocale,
        have_localeconv,
        lconv_size,
        have_decimal_point
    );
}