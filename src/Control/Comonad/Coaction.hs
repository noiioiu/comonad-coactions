-- | A comonad coaction is a comonoid coaction in the category of endofunctors, what's the problem?
module Control.Comonad.Coaction
  ( LeftComodule (..),
    RightComodule (..),
    BiComodule (..),
    comonadTransLCoscale,
    comonadTransRCoscale,
    comonadTransBiCoscale,
  )
where

import Control.Comonad (Comonad (..))
import Control.Comonad.Identity (Identity (..))
import Control.Comonad.Trans.Class (ComonadTrans (..))
import Control.Comonad.Trans.Env (EnvT)
import Control.Comonad.Trans.Identity (IdentityT (..))
import Control.Comonad.Trans.Store (StoreT)
import Control.Comonad.Trans.Traced (TracedT)
import Data.Functor.Compose (Compose (..))

-- | Instances must satisfy the following laws:
--
-- * @'duplicate' '.' 'lduplicate' = 'fmap' 'lduplicate' '.' 'lduplicate'@
--
-- * @'extract' '.' 'lduplicate' = 'id'@
class (Comonad w, Functor f) => LeftComodule w f where
  lduplicate ::
    f a ->
    -- | left comonad coaction
    w (f a)

-- | Instances must satisfy the following laws:
--
-- * @'fmap' 'duplicate' '.' 'rduplicate' = 'rduplicate' '.' 'rduplicate'@
--
-- * @'fmap' 'extract' '.' 'lduplicate' = 'id'@
class (Comonad w, Functor f) => RightComodule w f where
  rduplicate ::
    f a ->
    -- | right comonad coaction
    f (w a)

-- | Given two comonads r and s, an (r, s) bicomodule is a functor that is a left comodule over r and a right comodule over s, where the two coactions are compatible.
--   Instances must satisfy the following law in addition to the laws for @'LeftComodule'@ and @'RightComodule'@:
--
-- * @'lduplicate' '.' 'rduplicate' = 'fmap' 'rduplicate' '.' 'lduplicate' = 'bicoact'@
class (LeftComodule r f, RightComodule s f) => BiComodule r s f where
  bicoact ::
    f a ->
    -- | two-sided comonad coaction
    r (f (s a))
  bicoact = lduplicate . rduplicate

instance (Comonad w) => LeftComodule w w where
  lduplicate = duplicate

instance (Comonad w) => RightComodule w w where
  rduplicate = duplicate

instance (Comonad w) => BiComodule w w w where
  bicoact = duplicate . duplicate

instance (Comonad w) => LeftComodule Identity w where
  lduplicate = Identity

instance (Comonad w) => RightComodule Identity w where
  rduplicate = fmap Identity

instance (Comonad w) => BiComodule Identity Identity w where
  bicoact = Identity . fmap Identity

instance (Comonad w, Functor f, LeftComodule w v) => LeftComodule w (Compose v f) where
  lduplicate = fmap Compose . lduplicate . getCompose

instance (Comonad w, Functor f, RightComodule w v) => RightComodule w (Compose f v) where
  rduplicate = Compose . fmap rduplicate . getCompose

instance (Comonad s, Comonad t, Functor f, LeftComodule s u, RightComodule t v) => BiComodule s t (Compose u (Compose f v))

-- | Default left scalar comultiplication for comonad transformers.
--
--   No laws are given in the dicumentation for @'ComonadTrans'@, but we suppose they satisfy the following laws,
--   dual to the laws for @'MonadTrans'@:
--
--   * @'extract' '.' 'lower' = 'extract'@
--
--   * @'duplicate' '.' 'lower' = 'lower' '.' 'fmap' 'lower' . 'duplicate'@
--
--   The proofs of the comodule laws may be obtained by looking at the corresponding
--   proofs of the module laws in a mirror.
comonadTransLCoscale :: (Comonad w, ComonadTrans t, Comonad (t w)) => t w a -> w (t w a)
comonadTransLCoscale = lower . duplicate

instance (Comonad w) => LeftComodule w (IdentityT w) where lduplicate = comonadTransLCoscale

instance (Comonad w) => LeftComodule w (EnvT e w) where lduplicate = comonadTransLCoscale

instance (Comonad w) => LeftComodule w (StoreT s w) where lduplicate = comonadTransLCoscale

instance (Comonad w, Monoid m) => LeftComodule w (TracedT m w) where lduplicate = comonadTransLCoscale

-- | Default right scalar comultiplication for comonad transformers.
comonadTransRCoscale :: (Comonad w, ComonadTrans t, Comonad (t w)) => t w a -> t w (w a)
comonadTransRCoscale = fmap lower . duplicate

instance (Comonad m) => RightComodule m (IdentityT m) where rduplicate = comonadTransRCoscale

instance (Comonad m) => RightComodule m (EnvT e m) where rduplicate = comonadTransRCoscale

instance (Comonad m) => RightComodule m (StoreT s m) where rduplicate = comonadTransRCoscale

instance (Comonad w, Monoid m) => RightComodule w (TracedT m w) where rduplicate = comonadTransRCoscale

-- | Default two-sided scalar comultiplication for comonad transformers.
comonadTransBiCoscale :: (Comonad w, ComonadTrans t, Comonad (t w)) => t w a -> w (t w (w a))
comonadTransBiCoscale = fmap (fmap lower) . lower . duplicate . duplicate

instance (Comonad m) => BiComodule m m (IdentityT m) where bicoact = comonadTransBiCoscale

instance (Comonad m) => BiComodule m m (EnvT e m) where bicoact = comonadTransBiCoscale

instance (Comonad m) => BiComodule m m (StoreT s m) where bicoact = comonadTransBiCoscale

instance (Comonad w, Monoid m) => BiComodule w w (TracedT m w) where bicoact = comonadTransBiCoscale
