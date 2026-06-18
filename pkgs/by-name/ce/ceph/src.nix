{
  applyPatches,
  fetchpatch2,
  fetchurl,
}:

applyPatches (final: {
  pname = "ceph-src";
  version = "20.2.4";

  src = fetchurl {
    url = "https://download.ceph.com/tarballs/ceph-${final.version}.tar.gz";
    hash = "sha256-XzRWkkGiiQRGuTHwbNhE+TvKZl90CiBjFCnS1Vsemzc=";
  };

  patches = [
    # required to be able to compile s3select against nixpkgs' arrow-cpp
    # See: https://github.com/ceph/s3select/pull/169
    (fetchpatch2 {
      name = "ceph-s3select-arrow-cpp-20.patch";
      url = "https://github.com/ceph/s3select/pull/169.diff?full_index=1";
      extraPrefix = "src/s3select/";
      stripLen = 1;
      hash = "sha256-0jn5X4jIdluCufFXWHeO6skMz6XQpliHkC1tPLK6dbk=";
    })
    # arrow-cpp 24 dropped the `arrow/util/span.h` header and switched its
    # parquet encryption API from `arrow::util::span` to `std::span`.
    # Must be applied on top of the s3select patch above, which introduces the
    # vendored headers this touches.
    ./patches/0002-s3select-std-span.patch
    # fixes issues when python3 is not on the PATH
    # See: https://github.com/ceph/ceph/pull/67904
    ./patches/0001-mgr-python-interpreter.patch
    # fixes compilation on the gcc version present in nixos-unstable
    # See: https://github.com/ceph/ceph/pull/67081
    (fetchpatch2 {
      name = "ceph-20.2.1-backport-gcc16-fixes.patch";
      url = "https://aur.archlinux.org/cgit/aur.git/plain/ceph-20.2.1-backport-gcc16-fixes.patch?h=ceph&id=b158fda8a3e3834a7aa362954dc17077dc46f609";
      hash = "sha256-uLl20Sdd+JJFWqbMHIZRt53OpGRXlTaceajgpzYCaTM=";
      excludes = [
        # these cause CMake dependency cycles
        "src/test/CMakeLists.txt"
        "src/rgw/CMakeLists.txt"
      ];
    })
    # fixes compilation on the gcc version present in nixos-unstable
    # See: https://github.com/ceph/ceph/pull/69166
    (fetchpatch2 {
      name = "ceph-20.2.4-radosgw-gcc16-fixes.patch";
      url = "https://github.com/ceph/ceph/pull/69166.patch?full_index=1";
      hash = "sha256-yaqOrmw0ZItT2efzNfpDqjTRsva8VN0R+TLqbTX0snc=";
    })
    # Fixes for the tests below. They can be dropped once they are in a 20.2.x
    # release (backported to the tentacle branch) or once ceph is upgraded to a
    # release branched off main after they were merged.

    # fixes an uninitialized value and a hardcoded /bin path in the tests
    # See: https://github.com/ceph/ceph/pull/69560
    ./patches/0003-mds-fix-uninitialized-value-in-QuiesceAgent.patch
    ./patches/0004-rgw-don-t-hardcode-bin-in-test-ceph-diff-sorted.patch
    # fixes nondeterministic readable.sh and check-generated.sh failures from
    # uninitialized values; 0006 is backported to 20.2, which lacks the flags field
    # See: https://github.com/ceph/ceph/pull/73289
    ./patches/0005-osd-initialize-pg_fast_info_t-partial_writes_last_co.patch
    ./patches/0011-osd-initialize-remaining-pg_fast_info_t-fields.patch
    ./patches/0006-common-initialize-SnapRealmInfoNew-change_attr.patch
    # fixes building unittest_osdmap
    # See: https://github.com/ceph/ceph/pull/65509
    (fetchpatch2 {
      name = "ceph-test-add-missing-includes.patch";
      url = "https://github.com/ceph/ceph/commit/073584877f5fee617645ec9845de90a38777161d.patch?full_index=1";
      hash = "sha256-2p63yldwu2R0VqsLaHN9g1rkRRY0+6ZNc1lV6ORwrjE=";
    })
    # fixes linking unittest_dbstore_mgr_tests against a system gtest; main no
    # longer builds this test (https://github.com/ceph/ceph/pull/68291), so this
    # only needs to go into tentacle
    # TODO: link the tentacle PR
    ./patches/0008-rgw-dbstore-link-unittest_dbstore_mgr_tests-against-.patch
    # fixes unittest_mds_quiesce_agent in release builds
    # See: https://github.com/ceph/ceph/pull/69157
    (fetchpatch2 {
      name = "ceph-test-mds-await-idle-ndebug.patch";
      url = "https://github.com/ceph/ceph/commit/5a83c603876ad5b1fd8bd71044b624e9819a7832.patch?full_index=1";
      hash = "sha256-zsW1ULYwpnuJzUnL2bdrd7Wfus5QBBTtwkYu55iOKdU=";
    })
    # fixes unittest_ecbackend with allocators that don't page-align buffers
    # See: https://github.com/ceph/ceph/pull/66849
    (fetchpatch2 {
      name = "ceph-test-osd-ecbackend-buffer-alignment.patch";
      url = "https://github.com/ceph/ceph/commit/915a071c90f46b7be94d21e63556e0d2f8bd2c9b.patch?full_index=1";
      hash = "sha256-M0iFMPU7+witDk4zo333Oi8K59HIqABjIq2H6MIr9ig=";
    })
    # fixes nondeterministic check-generated.sh failures
    # See: https://github.com/ceph/ceph/pull/69604
    (fetchpatch2 {
      name = "ceph-mgr-perfcountertype-initialize.patch";
      url = "https://github.com/ceph/ceph/commit/61b21c04f4e4519650220dd3c4737976b37268b9.patch?full_index=1";
      hash = "sha256-tVao7M/dFF7zNeztLv9GD28hMAPxJOYYxj7NgJnevUc=";
    })
  ];
})
