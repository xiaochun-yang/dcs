#ifndef SCITBX_MAT3_H
#define SCITBX_MAT3_H

#include <utility>
#include <scitbx/error.h>
#include <scitbx/array_family/tiny_plain.h>

namespace scitbx {

  // forward declaration
  template <typename NumType>
  class sym_mat3;

  //! Matrix class (3x3).
  /*! This class represents a 3x3 matrix that can be used to store
      linear transformations.

      Enhanced version of the python mat3 class by
      Matthias Baas (baas@ira.uka.de). See
      http://cgkit.sourceforge.net/
      for more information.
   */
  template <typename NumType>
  class mat3 : public af::tiny_plain<NumType, 9>
  {
    public:
      typedef typename af::tiny_plain<NumType, 9> base_type;

      //! Default constructor. Elements are not initialized.
      mat3() {}
      //! Constructor.
      mat3(NumType const& e00, NumType const& e01, NumType const& e02,
           NumType const& e10, NumType const& e11, NumType const& e12,
           NumType const& e20, NumType const& e21, NumType const& e22)
        : base_type(e00, e01, e02, e10, e11, e12, e20, e21, e22)
      {}
      //! Constructor.
      mat3(base_type const& a)
        : base_type(a)
      {}
      //! Constructor.
      explicit
      mat3(const NumType* a)
      {
        for(std::size_t i=0;i<9;i++) this->elems[i] = a[i];
      }
      //! Constructor for diagonal matrix.
      explicit
      mat3(NumType const& diag)
        : base_type(diag,0,0,0,diag,0,0,0,diag)
      {}
      //! Constructor for diagonal matrix.
      explicit
      mat3(af::tiny_plain<NumType,3> const& diag)
        : base_type(diag[0],0,0,0,diag[1],0,0,0,diag[2])
      {}
      //! Construction from symmetric matrix.
      explicit
      inline
      mat3(sym_mat3<NumType> const& m);

      //! Access elements with 2-dimensional indices.
      NumType const&
      operator()(std::size_t r, std::size_t c) const
      {
        return this->elems[r * 3 + c];
      }
      //! Access elements with 2-dimensional indices.
      NumType&
      operator()(std::size_t r, std::size_t c)
      {
        return this->elems[r * 3 + c];
      }

      //! Set a row.
      void
      set_row(std::size_t i, af::tiny_plain<NumType,3> const& v)
      {
        std::copy(v.begin(), v.end(), &this->elems[i * 3]);
      }

      //! Swap two rows in place.
      void
      swap_rows(std::size_t i1, std::size_t i2)
      {
        std::swap_ranges(&(*this)(i1,0), &(*this)(i1+1,0), &(*this)(i2,0));
      }

      //! Set a column.
      void
      set_column(std::size_t i, af::tiny_plain<NumType,3> const& v)
      {
        for(std::size_t j=0;j<3;j++) this->elems[j * 3 + i] = v[j];
      }

      //! Swap two columns in place.
      void
      swap_columns(std::size_t i1, std::size_t i2)
      {
        for(std::size_t i=0;i<9;i+=3) {
          std::swap(this->elems[i + i1], this->elems[i + i2]);
        }
      }

      //! Return the transposed matrix.
      mat3
      transpose() const
      {
        mat3 const& m = *this;
        return mat3(m[0], m[3], m[6],
                    m[1], m[4], m[7],
                    m[2], m[5], m[8]);
      }

      //! Return determinant.
      NumType
      determinant() const
      {
        mat3 const& m = *this;
        return   m[0] * (m[4] * m[8] - m[5] * m[7])
               - m[1] * (m[3] * m[8] - m[5] * m[6])
               + m[2] * (m[3] * m[7] - m[4] * m[6]);
      }

      //! Test for symmetric matrix.
      /*! Returns false iff the absolute value of the difference between
          any pair of off-diagonal elements is different from zero.
       */
      bool
      is_symmetric() const
      {
        mat3 const& m = *this;
        return    m[1] == m[3]
               && m[2] == m[6]
               && m[5] == m[7];
      }

      //! Return the transposed of the co-factor matrix.
      /*! The inverse matrix is obtained by dividing the result
          by the determinant().
       */
      mat3
      co_factor_matrix_transposed() const
      {
        mat3 const& m = *this;
        return mat3(
           m[4] * m[8] - m[5] * m[7],
          -m[1] * m[8] + m[2] * m[7],
           m[1] * m[5] - m[2] * m[4],
          -m[3] * m[8] + m[5] * m[6],
           m[0] * m[8] - m[2] * m[6],
          -m[0] * m[5] + m[2] * m[3],
           m[3] * m[7] - m[4] * m[6],
          -m[0] * m[7] + m[1] * m[6],
           m[0] * m[4] - m[1] * m[3]);
      }

      //! Return the inverse matrix.
      /*! An exception is thrown if the matrix is not invertible,
          i.e. if the determinant() is zero.
       */
      mat3
      inverse() const
      {
        NumType d = determinant();
        if (d == NumType(0)) throw error("Matrix is not invertible.");
        return co_factor_matrix_transposed() / d;
      }

      //! Returns the inverse matrix, after minimizing the error numerically.
      /*! Here's the theory:
          M*M^-1 = I-E, where E is the error
          M*M^-1*(I+E) = (I-E)*(I+E)
          M*(M^-1*(I+E)) = I^2-E^2
          M*(M^-1*(I+E)) = I-E^2
                      let M^-1*(I+E)  = M1
                      let E^2         = E2
          M*M1*(I+E2) = (I-E2)*(I+E2)
          M*M2 = I-E4
          M*Mi = I-E2^i
          Supposedly this will drive the error pretty low after
          only a few repetitions. The error rate should be ~E^(2^iterations),
          which I think is pretty good. This assumes that E is "<< 1",
          whatever that means. Attributed to Judah I. Rosenblatt.

          2*I - (I-E) ==> 2*I - I + E = I + E
       */
      mat3
      error_minimizing_inverse ( std::size_t iterations ) const
      {
        mat3 inverse = this->inverse();
        if ( 0 == iterations )
                      return inverse;
              mat3 two_diagonal(2);
        for ( std::size_t i=0; i<iterations; ++i )
                inverse = inverse * (two_diagonal - this*inverse);
        return inverse;
      }

      //! Scale matrix in place.
      /*! Each row of this is multiplied element-wise with v.
       */
      mat3&
      scale(af::tiny_plain<NumType,3> const& v)
      {
        for(std::size_t i=0;i<9;) {
          for(std::size_t j=0;j<3;j++,i++) {
            this->elems[i] *= v[j];
          }
        }
        return *this;
      }

      //! Return a matrix with orthogonal base vectors.
      mat3 ortho() const;

      //! (*this) * this->transpose().
      inline
      sym_mat3<NumType>
      self_times_self_transpose() const;

      //! this->transpose() * (*this).
      inline
      sym_mat3<NumType>
      self_transpose_times_self() const;

      //! Sum of element-wise products.
      inline
      NumType
      dot(mat3 const& other)
      {
        mat3 const& m = *this;
        return m[0] * other[0]
             + m[1] * other[1]
             + m[2] * other[2]
             + m[3] * other[3]
             + m[4] * other[4]
             + m[5] * other[5]
             + m[6] * other[6]
             + m[7] * other[7]
             + m[8] * other[8];
      }
  };

  //! Test equality.
  template <typename NumType>
  inline
  bool
  operator==(
    mat3<NumType> const& lhs,
    mat3<NumType> const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      if (lhs[i] != rhs[i]) return false;
    }
    return true;
  }

  //! Test equality. True if all elements of lhs == rhs.
  template <typename NumType>
  inline
  bool
  operator==(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      if (lhs[i] != rhs   ) return false;
    }
    return true;
  }

  //! Test equality. True if all elements of rhs == lhs.
  template <typename NumType>
  inline
  bool
  operator==(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      if (lhs    != rhs[i]) return false;
    }
    return true;
  }

  //! Test inequality.
  template <typename NumType>
  inline
  bool
  operator!=(
    mat3<NumType> const& lhs,
    mat3<NumType> const& rhs)
  {
    return !(lhs == rhs);
  }

  //! Test inequality. True if any element of lhs != rhs.
  template <typename NumType>
  inline
  bool
  operator!=(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    return !(lhs == rhs);
  }

  //! Test inequality. True if any element of rhs != lhs.
  template <typename NumType>
  inline
  bool
  operator!=(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    return !(lhs == rhs);
  }

  //! Element-wise addition.
  template <typename NumType>
  inline
  mat3<NumType>
  operator+(
    mat3<NumType> const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] + rhs[i];
    }
    return result;
  }

  //! Element-wise addition.
  template <typename NumType>
  inline
  mat3<NumType>
  operator+(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] + rhs   ;
    }
    return result;
  }

  //! Element-wise addition.
  template <typename NumType>
  inline
  mat3<NumType>
  operator+(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs    + rhs[i];
    }
    return result;
  }

  //! Element-wise difference.
  template <typename NumType>
  inline
  mat3<NumType>
  operator-(
    mat3<NumType> const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] - rhs[i];
    }
    return result;
  }

  //! Element-wise difference.
  template <typename NumType>
  inline
  mat3<NumType>
  operator-(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] - rhs   ;
    }
    return result;
  }

  //! Element-wise difference.
  template <typename NumType>
  inline
  mat3<NumType>
  operator-(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs    - rhs[i];
    }
    return result;
  }

  //! Element-wise multiplication.
  template <typename NumType>
  inline
  mat3<NumType>
  operator*(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] * rhs   ;
    }
    return result;
  }

  //! Element-wise multiplication.
  template <typename NumType>
  inline
  mat3<NumType>
  operator*(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs    * rhs[i];
    }
    return result;
  }

  //! Element-wise division.
  template <typename NumType>
  inline
  mat3<NumType>
  operator/(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] / rhs   ;
    }
    return result;
  }

  //! Element-wise division.
  template <typename NumType>
  inline
  mat3<NumType>
  operator/(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs    / rhs[i];
    }
    return result;
  }

  //! Element-wise modulus operation.
  template <typename NumType>
  inline
  mat3<NumType>
  operator%(
    mat3<NumType> const& lhs,
    NumType const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs[i] % rhs   ;
    }
    return result;
  }

  //! Element-wise modulus operation.
  template <typename NumType>
  inline
  mat3<NumType>
  operator%(
    NumType const& lhs,
    mat3<NumType> const& rhs)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = lhs    % rhs[i];
    }
    return result;
  }

  //! Element-wise in-place addition.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator+=(
    mat3<NumType>& lhs,
    mat3<NumType> const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] += rhs[i];
    }
    return lhs;
  }

  //! Element-wise in-place addition.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator+=(
    mat3<NumType>& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] += rhs   ;
    }
    return lhs;
  }

  //! Element-wise in-place difference.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator-=(
    mat3<NumType>& lhs,
    mat3<NumType> const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] -= rhs[i];
    }
    return lhs;
  }

  //! Element-wise in-place difference.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator-=(
    mat3<NumType>& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] -= rhs   ;
    }
    return lhs;
  }

  //! Element-wise in-place multiplication.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator*=(
    mat3<NumType>& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] *= rhs   ;
    }
    return lhs;
  }

  //! Element-wise in-place division.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator/=(
    mat3<NumType>& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] /= rhs   ;
    }
    return lhs;
  }

  //! Element-wise in-place modulus operation.
  template <typename NumType>
  inline
  mat3<NumType>&
  operator%=(
    mat3<NumType>& lhs,
    NumType const& rhs)
  {
    for(std::size_t i=0;i<9;i++) {
      lhs[i] %= rhs   ;
    }
    return lhs;
  }

  //! Element-wise unary minus.
  template <typename NumType>
  inline
  mat3<NumType>
  operator-(
    mat3<NumType> const& v)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = -v[i];
    }
    return result;
  }

  //! Element-wise unary plus.
  template <typename NumType>
  inline
  mat3<NumType>
  operator+(
    mat3<NumType> const& v)
  {
    mat3<NumType> result;
    for(std::size_t i=0;i<9;i++) {
      result[i] = +v[i];
    }
    return result;
  }

} // namespace scitbx

#endif // SCITBX_MAT3_H