{-# LANGUAGE CPP #-}

#ifdef __GLASGOW_HASKELL__
{-# LANGUAGE DeriveDataTypeable #-}

# if __GLASGOW_HASKELL__ >= 704
{-# LANGUAGE DeriveGeneric #-}
# endif

#endif
-----------------------------------------------------------------------------
-- |
-- Module      :  Bound.Var
-- Copyright   :  (C) 2012 Edward Kmett
-- License     :  BSD-style (see the file LICENSE)
--
-- Maintainer  :  Edward Kmett <ekmett@gmail.com>
-- Stability   :  experimental
-- Portability :  portable
--
----------------------------------------------------------------------------
module Bound.Var
  ( Var(..)
  , unvar
  ) where

import Control.Applicative
import Control.Monad (ap)
import Data.Foldable
import Data.Traversable
import Data.Monoid (mempty)
import Data.Bifunctor
import Data.Bifoldable
import Data.Bitraversable
#ifdef __GLASGOW_HASKELL__
import Data.Data
# if __GLASGOW_HASKELL__ >= 704
import GHC.Generics
# endif
#endif
import Data.Profunctor
import Prelude.Extras

----------------------------------------------------------------------------
-- Bound and Free Variables
----------------------------------------------------------------------------

-- | \"I am not a number, I am a /free monad/!\"
--
-- A @'Var' b a@ is a variable that may either be \"bound\" ('B') or \"free\" ('F').
--
-- (It is also technically a free monad in the same near-trivial sense as
-- 'Either'.)
data Var b a
  = B b -- ^ this is a bound variable
  | F a -- ^ this is a free variable
  deriving
  ( Eq
  , Ord
  , Show
  , Read
#ifdef __GLASGOW_HASKELL__
  , Data
  , Typeable
# if __GLASGOW_HASKELL__ >= 704
  , Generic
# endif
#endif
  )

unvar :: (b -> r) -> (a -> r) -> Var b a -> r
unvar f _ (B b) = f b
unvar _ g (F a) = g a
{-# INLINE unvar #-}

-- |
-- This provides a @Prism@ that can be used with @lens@ library to access a bound 'Var'.
--
-- @
-- '_B' :: 'Prism' (Var b a) (Var b' a) b b'@
-- @
_B :: (Choice p, Applicative f) => p b (f b') -> p (Var b a) (f (Var b' a))
_B = dimap (unvar Right (Left . F)) (either pure (fmap B)) . right'

-- |
-- This provides a @Prism@ that can be used with @lens@ library to access a free 'Var'.
--
-- @
-- '_F' :: 'Prism' (Var b a) (Var b a') a a'@
-- @
_F :: (Choice p, Applicative f) => p a (f a') -> p (Var b a) (f (Var b a'))
_F = dimap (unvar (Left . B) Right) (either pure (fmap F)) . right'

----------------------------------------------------------------------------
-- Instances
----------------------------------------------------------------------------

instance Functor (Var b) where
  fmap _ (B b) = B b
  fmap f (F a) = F (f a)

instance Foldable (Var b) where
  foldMap f (F a) = f a
  foldMap _ _ = mempty

instance Traversable (Var b) where
  traverse f (F a) = F <$> f a
  traverse _ (B b) = pure (B b)

instance Applicative (Var b) where
  pure = F
  (<*>) = ap

instance Monad (Var b) where
  return = F
  F a  >>= f = f a
  B b >>= _ = B b

instance Bifunctor Var where
  bimap f _ (B b) = B (f b)
  bimap _ g (F a) = F (g a)

instance Bifoldable Var where
  bifoldMap f _ (B b) = f b
  bifoldMap _ g (F a) = g a

instance Bitraversable Var where
  bitraverse f _ (B b) = B <$> f b
  bitraverse _ g (F a) = F <$> g a

instance Eq2 Var   where (==##)     = (==)
instance Ord2 Var  where compare2   = compare
instance Show2 Var where showsPrec2 = showsPrec
instance Read2 Var where readsPrec2  = readsPrec

instance Eq b   => Eq1   (Var b) where (==#)      = (==)
instance Ord b  => Ord1  (Var b) where compare1   = compare
instance Show b => Show1 (Var b) where showsPrec1 = showsPrec
instance Read b => Read1 (Var b) where readsPrec1  = readsPrec