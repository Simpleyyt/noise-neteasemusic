pkg_check_modules(NETEASEMUSIC_DEPS libxml-2.0 json-glib-1.0 libsoup-2.4 nettle)

if (NETEASEMUSIC_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${NETEASEMUSIC_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${NETEASEMUSIC_DEPS_LIBRARIES} -lgmp)
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${NETEASEMUSIC_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME neteasemusic)
vala_precompile(NETEASE_MUSIC_VALA_C ${TARGET_NAME}
    NeteaseMusic.vala
    NeteaseMusicLibrary.vala
    NeteaseCoreApi.vala
    NeteaseApi.vala
    NeteaseView.vala
    NeteaseViewWrapper.vala
    PreferencesSection.vala
    Settings.vala
PACKAGES
    ${DEPS_PACKAGES}
    libxml-2.0
    json-glib-1.0
    libsoup-2.4
    noise-core
    nettle
    gmp
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi
)

add_library(${TARGET_NAME} MODULE ${NETEASE_MUSIC_VALA_C})

target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/NeteaseMusic/)
install(FILES neteasemusic.plugin DESTINATION ${PLUGIN_DIR}/NeteaseMusic/)

add_subdirectory(schemas)

else ()

message("-- Netease Music plugin disabled")

endif ()
