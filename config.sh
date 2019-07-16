function build_faiss {
    aclocal && autoconf
    if [ -n "$IS_OSX" ]; then
        ./configure --without-cuda --with-blas="-framework Accelerate"
        cat makefile.inc
    else
        ./configure --without-cuda
    fi
    make -j4 && make install
}

function pre_build {
    build_swig > /dev/null
    if [ -n "$IS_OSX" ]; then
        brew install libomp llvm > /dev/null
        local prefix=$(brew --prefix llvm)
        export CC="$prefix/bin/clang"
        export CXX="$prefix/bin/clang++"
        if [ "$MB_PYTHON_OSX_VER" != "10.9" ]; then
            export CXXFLAGS="-stdlib=libc++"
            export CFLAGS="-stdlib=libc++"
        fi
    else
        build_openblas > /dev/null
    fi
    (cd $REPO_DIR && build_faiss)
}

function pip_wheel_cmd {
    local abs_wheelhouse=$1
    # export FAISS_LDFLAGS="/usr/local/lib/libfaiss.a"
    if [ -n "$IS_OSX" ]; then
        export FAISS_LDFLAGS="libfaiss.a -framework Accelerate"
    else
        # export FAISS_LDFLAGS="$FAISS_LDFLAGS /usr/local/lib/libopenblas.a -lgfortran"
        if [ "$PYTHON_VERSION" = "3.6" ]; then
            python setup.py sdist --dist-dir $abs_wheelhouse
        fi
    fi
    pip wheel $(pip_opts) -w $abs_wheelhouse --no-deps .
}

function run_tests {
    python --version
    python -c "import faiss, numpy; faiss.Kmeans(10, 20).train(numpy.random.rand(1000, 10).astype(numpy.float32))"
}
