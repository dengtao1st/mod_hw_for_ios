#ifndef STR_OBFUSCATOR_HPP_
#define STR_OBFUSCATOR_HPP_

#if defined(_MSC_VER)
#define ALWAYS_INLINE __forceinline
#else
#define ALWAYS_INLINE __attribute__((always_inline))
#endif

namespace detail {
  template<std::size_t index>
  struct encryptor {
    ALWAYS_INLINE static constexpr void encrypt(char *dest, const char *str, char key) {
      dest[index] = str[index] ^ key;

      encryptor<index - 1>::encrypt(dest, str, key);
    }
  };

  template<>
  struct encryptor<0> {
    ALWAYS_INLINE static constexpr void encrypt(char *dest, const char *str, char key) {
      dest[0] = str[0] ^ key;
    }
  };
};

class cryptor {
public:
  template<std::size_t S>
  class string_encryptor {
  public:
    constexpr ALWAYS_INLINE string_encryptor(const char str[S], int key) :
      _buffer{}, _decrypted{ false }, _key{ static_cast<const char>(key % 255) } {
      constexpr char time[] = __TIME__;
      const int seed = DigitToInt(time[7]) +
        DigitToInt(time[6]) * 10 +
        DigitToInt(time[4]) * 60 +
        DigitToInt(time[3]) * 600 +
        DigitToInt(time[1]) * 3600 +
        DigitToInt(time[0]) * 36000;
      detail::encryptor<S - 1>::encrypt(_buffer, str, _key ^ seed);
    }

   ALWAYS_INLINE const char *decrypt() const {
      if (_decrypted) {
        return _buffer;
      }

      for (auto &c : _buffer) {
        c ^= _key;
      }

      _decrypted = true;

      return _buffer;
    }

  private:
    constexpr ALWAYS_INLINE int DigitToInt(char c) { return c - '0'; }
    mutable char _buffer[S];
    mutable bool _decrypted;
    const char _key;
  };

  template<std::size_t S>
  static constexpr ALWAYS_INLINE auto create(const char(&str)[S]) {
    return string_encryptor<S>{ str, S };
  }
};


#define STR_OBFUSCATOR(str) (cryptor::create(str).decrypt())

#endif // STR_OBFUSCATOR_HPP_
