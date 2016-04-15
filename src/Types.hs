{-# LANGUAGE
TemplateHaskell,
MultiParamTypeClasses,
FunctionalDependencies,
FlexibleContexts,
FlexibleInstances,
RecordWildCards,
TypeFamilies,
OverloadedStrings,
RankNTypes,
TupleSections,
NoImplicitPrelude
  #-}


{-# OPTIONS_GHC -fno-warn-orphans #-}


module Types
(
  Trait(..),
  ItemKind(..),
    hackageName,
  Item(..),
    group_,
    pros,
    prosDeleted,
    cons,
    consDeleted,
    ecosystem,
    link,
    kind,
  Hue(..),
    hueToDarkColor,
    hueToLightColor,
  Category(..),
    title,
    groups,
    items,
    itemsDeleted,
    categorySlug,
  GlobalState(..),
    categories,
    categoriesDeleted,
    pendingEdits,
    editIdCounter,

  -- * Overloaded things
  uid,
  hasUid,
  content,
  name,
  description,
  notes,
  created,

  -- * Edits
  Edit(..),
    isVacuousEdit,
  EditDetails(..),

  -- * acid-state methods
  -- ** query
  GetGlobalState(..),
  GetCategories(..),
  GetCategory(..), GetCategoryMaybe(..),
  GetCategoryByItem(..),
  GetItem(..),
  GetTrait(..),

  -- ** add
  AddCategory(..),
  AddItem(..),
  AddPro(..),
  AddCon(..),

  -- ** set
  SetGlobalState(..),
  -- *** 'Category'
  SetCategoryTitle(..),
  SetCategoryNotes(..),
  -- *** 'Item'
  SetItemName(..),
  SetItemLink(..),
  SetItemGroup(..),
  SetItemKind(..),
  SetItemDescription(..),
  SetItemNotes(..),
  SetItemEcosystem(..),
  -- *** 'Trait'
  SetTraitContent(..),

  -- ** delete
  DeleteCategory(..),
  DeleteItem(..),
  DeleteTrait(..),

  -- ** edits
  GetEdit(..), GetEdits(..),
  RegisterEdit(..),
  RemovePendingEdit(..), RemovePendingEdits(..),

  -- ** other
  MoveItem(..),
  MoveTrait(..),
  RestoreCategory(..),
  RestoreItem(..),
  RestoreTrait(..),
  )
where


-- General
import BasePrelude hiding (Category)
-- Monads and monad transformers
import Control.Monad.State
import Control.Monad.Reader
-- Lenses
import Lens.Micro.Platform hiding ((&))
-- Containers
import qualified Data.Map as M
import Data.Map (Map)
-- Text
import qualified Data.Text as T
import Data.Text (Text)
-- Time
import Data.Time
-- Network
import Data.IP
-- acid-state
import Data.SafeCopy hiding (kind)
import Data.Acid as Acid

-- Local
import Utils
import Markdown


data Trait = Trait {
  _traitUid :: Uid Trait,
  _traitContent :: MarkdownInline }
  deriving (Eq, Show)

-- See Note [acid-state]
deriveSafeCopySimple 2 'extension ''Trait
makeFields ''Trait

-- Old version, needed for safe migration. It can most likely be already
-- deleted (if a checkpoint has been created), but it's been left here as a
-- template for future migrations.
--
-- Again, see Note [acid-state].
data Trait_v1 = Trait_v1 {
  _traitUid_v1 :: Uid Trait,
  _traitContent_v1 :: MarkdownInline }

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 1 'base ''Trait_v1

instance Migrate Trait where
  type MigrateFrom Trait = Trait_v1
  migrate Trait_v1{..} = Trait {
    _traitUid = _traitUid_v1,
    _traitContent = _traitContent_v1 }

--

data ItemKind
  = Library {_itemKindHackageName :: Maybe Text}
  | Tool {_itemKindHackageName :: Maybe Text}
  | Other
  deriving (Eq, Show)

deriveSafeCopySimple 3 'extension ''ItemKind
makeFields ''ItemKind

data ItemKind_v2
  = Library_v2 {_itemKindHackageName_v2 :: Maybe Text}
  | Tool_v2 {_itemKindHackageName_v2 :: Maybe Text}
  | Other_v2

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 2 'base ''ItemKind_v2

instance Migrate ItemKind where
  type MigrateFrom ItemKind = ItemKind_v2
  migrate Library_v2{..} = Library {
    _itemKindHackageName = _itemKindHackageName_v2 }
  migrate Tool_v2{..} = Tool {
    _itemKindHackageName = _itemKindHackageName_v2 }
  migrate Other_v2 = Other

--

-- TODO: add a field like “people to ask on IRC about this library if you
-- need help”
data Item = Item {
  _itemUid         :: Uid Item,
  _itemName        :: Text,
  _itemCreated     :: UTCTime,
  _itemGroup_      :: Maybe Text,
  _itemDescription :: MarkdownBlock,
  _itemPros        :: [Trait],
  _itemProsDeleted :: [Trait],
  _itemCons        :: [Trait],
  _itemConsDeleted :: [Trait],
  _itemEcosystem   :: MarkdownBlock,
  _itemNotes       :: MarkdownBlock,
  _itemLink        :: Maybe Url,
  _itemKind        :: ItemKind }
  deriving (Eq, Show)

deriveSafeCopySimple 8 'extension ''Item
makeFields ''Item

-- Old version, needed for safe migration. It can most likely be already
-- deleted (if a checkpoint has been created), but it's been left here as a
-- template for future migrations.
data Item_v7 = Item_v7 {
  _itemUid_v7         :: Uid Item,
  _itemName_v7        :: Text,
  _itemCreated_v7     :: UTCTime,
  _itemGroup__v7      :: Maybe Text,
  _itemDescription_v7 :: MarkdownBlock,
  _itemPros_v7        :: [Trait],
  _itemProsDeleted_v7 :: [Trait],
  _itemCons_v7        :: [Trait],
  _itemConsDeleted_v7 :: [Trait],
  _itemEcosystem_v7   :: MarkdownBlock,
  _itemNotes_v7       :: MarkdownBlock,
  _itemLink_v7        :: Maybe Url,
  _itemKind_v7        :: ItemKind }

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 7 'base ''Item_v7

instance Migrate Item where
  type MigrateFrom Item = Item_v7
  migrate Item_v7{..} = Item {
    _itemUid = _itemUid_v7,
    _itemName = _itemName_v7,
    _itemCreated = _itemCreated_v7,
    _itemGroup_ = _itemGroup__v7,
    _itemDescription = _itemDescription_v7,
    _itemPros = _itemPros_v7,
    _itemProsDeleted = _itemProsDeleted_v7,
    _itemCons = _itemCons_v7,
    _itemConsDeleted = _itemConsDeleted_v7,
    _itemEcosystem = _itemEcosystem_v7,
    _itemNotes = _itemNotes_v7,
    _itemLink = _itemLink_v7,
    _itemKind = _itemKind_v7 }

--

data Hue = NoHue | Hue Int
  deriving (Eq, Ord)

deriveSafeCopySimple 1 'extension ''Hue

data Hue_v0 = NoHue_v0 | Hue_v0 Int

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 0 'base ''Hue_v0

instance Migrate Hue where
  type MigrateFrom Hue = Hue_v0
  migrate NoHue_v0 = NoHue
  migrate (Hue_v0 i) = Hue i

instance Show Hue where
  show NoHue   = "0"
  show (Hue n) = show n

{-
https://www.google.com/design/spec/style/color.html#color-color-palette

                50     100    200
              ------ ------ ------
red         : FFEBEE FFCDD2 EF9A9A
pink        : FCE4EC F8BBD0 F48FB1
purple      : F3E5F5 E1BEE7 CE93D8
deep purple : EDE7F6 D1C4E9 B39DDB
indigo      : E8EAF6 C5CAE9 9FA8DA
blue        : E3F2FD BBDEFB 90CAF9
light blue  : E1F5FE B3E5FC 81D4FA
cyan        : E0F7FA B2EBF2 80DEEA
teal        : E0F2F1 B2DFDB 80CBC4
green       : E8F5E9 C8E6C9 A5D6A7
light green : F1F8E9 DCEDC8 C5E1A5
lime        : F9FBE7 F0F4C3 E6EE9C
yellow      : FFFDE7 FFF9C4 FFF59D
amber       : FFF8E1 FFECB3 FFE082
orange      : FFF3E0 FFE0B2 FFCC80
deep orange : FBE9E7 FFCCBC FFAB91
brown       : EFEBE9 D7CCC8 BCAAA4
gray        : FAFAFA F5F5F5 EEEEEE
blue gray   : ECEFF1 CFD8DC B0BEC5
-}

-- TODO: more colors and don't repeat them!
-- TODO: check how all colors look (not just deep purple)
hueToDarkColor :: Hue -> Text
hueToDarkColor NoHue = "#D6D6D6"  -- the color for gray isn't from Google's
                                  -- palette, since their “100” is too light
hueToDarkColor (Hue i) = table !! ((i-1) `mod` length table)
  where
    -- the “100” colors
    table = ["#D1C4E9",   -- deep purple
             "#C8E6C9",   -- green
             "#FFECB3",   -- amber
             "#FFCDD2"]   -- red

hueToLightColor :: Hue -> Text
hueToLightColor NoHue = "#F0F0F0"  -- the color for gray isn't from Google's
                                   -- palette, since their “50” is too light
hueToLightColor (Hue i) = table !! ((i-1) `mod` length table)
  where
    -- the “50” colors
    table = ["#EDE7F6",
             "#E8F5E9",
             "#FFF8E1",
             "#FFEBEE"]

--

data Category = Category {
  _categoryUid :: Uid Category,
  _categoryTitle :: Text,
  _categoryCreated :: UTCTime,
  _categoryNotes :: MarkdownBlock,
  _categoryGroups :: Map Text Hue,
  _categoryItems :: [Item],
  _categoryItemsDeleted :: [Item] }
  deriving (Eq, Show)

deriveSafeCopySimple 4 'extension ''Category
makeFields ''Category

categorySlug :: Category -> Text
categorySlug category =
  format "{}-{}" (makeSlug (category^.title), category^.uid)

-- Old version, needed for safe migration. It can most likely be already
-- deleted (if a checkpoint has been created), but it's been left here as a
-- template for future migrations.
data Category_v3 = Category_v3 {
  _categoryUid_v3 :: Uid Category,
  _categoryTitle_v3 :: Text,
  _categoryCreated_v3 :: UTCTime,
  _categoryNotes_v3 :: MarkdownBlock,
  _categoryGroups_v3 :: Map Text Hue,
  _categoryItems_v3 :: [Item],
  _categoryItemsDeleted_v3 :: [Item] }

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 3 'base ''Category_v3

instance Migrate Category where
  type MigrateFrom Category = Category_v3
  migrate Category_v3{..} = Category {
    _categoryUid = _categoryUid_v3,
    _categoryTitle = _categoryTitle_v3,
    _categoryCreated = _categoryCreated_v3,
    _categoryNotes = _categoryNotes_v3,
    _categoryGroups = _categoryGroups_v3,
    _categoryItems = _categoryItems_v3,
    _categoryItemsDeleted = _categoryItemsDeleted_v3 }

-- Edits

-- | Edits made by users. It should always be possible to undo an edit.
data Edit
  -- Add
  = Edit'AddCategory {
      editCategoryUid   :: Uid Category,
      editCategoryTitle :: Text }
  | Edit'AddItem {
      editCategoryUid   :: Uid Category,
      editItemUid       :: Uid Item,
      editItemName      :: Text }
  | Edit'AddPro {
      editItemUid       :: Uid Item,
      editTraitId       :: Uid Trait,
      editTraitContent  :: Text }
  | Edit'AddCon {
      editItemUid       :: Uid Item,
      editTraitId       :: Uid Trait,
      editTraitContent  :: Text }

  -- Change category properties
  | Edit'SetCategoryTitle {
      editCategoryUid      :: Uid Category,
      editCategoryTitle    :: Text,
      editCategoryNewTitle :: Text }
  | Edit'SetCategoryNotes {
      editCategoryUid      :: Uid Category,
      editCategoryNotes    :: Text,
      editCategoryNewNotes :: Text }

  -- Change item properties
  | Edit'SetItemName {
      editItemUid            :: Uid Item,
      editItemName           :: Text,
      editItemNewName        :: Text }
  | Edit'SetItemLink {
      editItemUid            :: Uid Item,
      editItemLink           :: Maybe Url,
      editItemNewLink        :: Maybe Url }
  | Edit'SetItemGroup {
      editItemUid            :: Uid Item,
      editItemGroup          :: Maybe Text,
      editItemNewGroup       :: Maybe Text }
  | Edit'SetItemKind {
      editItemUid            :: Uid Item,
      editItemKind           :: ItemKind,
      editItemNewKind        :: ItemKind }
  | Edit'SetItemDescription {
      editItemUid            :: Uid Item,
      editItemDescription    :: Text,
      editItemNewDescription :: Text }
  | Edit'SetItemNotes {
      editItemUid            :: Uid Item,
      editItemNotes          :: Text,
      editItemNewNotes       :: Text }
  | Edit'SetItemEcosystem {
      editItemUid            :: Uid Item,
      editItemEcosystem      :: Text,
      editItemNewEcosystem   :: Text }

  -- Change trait properties
  | Edit'SetTraitContent {
      editItemUid         :: Uid Item,
      editTraitUid        :: Uid Trait,
      editTraitContent    :: Text,
      editTraitNewContent :: Text }

  -- Delete
  | Edit'DeleteCategory {
      editCategoryUid       :: Uid Category,
      editCategoryPosition  :: Int }
  | Edit'DeleteItem {
      editItemUid           :: Uid Item,
      editItemPosition      :: Int }
  | Edit'DeleteTrait {
      editItemUid           :: Uid Item,
      editTraitUid          :: Uid Trait,
      editTraitPosition     :: Int }

  -- Other
  | Edit'MoveItem {
      editItemUid   :: Uid Item,
      editDirection :: Bool }
  | Edit'MoveTrait {
      editItemUid   :: Uid Item,
      editTraitUid  :: Uid Trait,
      editDirection :: Bool }

  deriving (Eq, Show)

deriveSafeCopySimple 2 'extension ''Edit

genVer ''Edit 1 [
  -- Add
  Copy 'Edit'AddCategory,
  Copy 'Edit'AddItem,
  Copy 'Edit'AddPro,
  Copy 'Edit'AddCon,
  -- Change category properties
  Copy 'Edit'SetCategoryTitle,
  Copy 'Edit'SetCategoryNotes,
  -- Change item properties
  Copy 'Edit'SetItemName,
  Copy 'Edit'SetItemLink,
  Copy 'Edit'SetItemGroup,
  Copy 'Edit'SetItemKind,
  Copy 'Edit'SetItemDescription,
  Copy 'Edit'SetItemNotes,
  Copy 'Edit'SetItemEcosystem,
  -- Change trait properties
  Copy 'Edit'SetTraitContent,
  -- Delete
  Copy 'Edit'DeleteCategory,
  Copy 'Edit'DeleteItem,
  Copy 'Edit'DeleteTrait,
  -- Other
  Copy 'Edit'MoveItem,
  Copy 'Edit'MoveTrait ]

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 1 'base ''Edit_v1

instance Migrate Edit where
  type MigrateFrom Edit = Edit_v1
  migrate = $(migrateVer ''Edit 1 [
    CopyM 'Edit'AddCategory,
    CopyM 'Edit'AddItem,
    CopyM 'Edit'AddPro,
    CopyM 'Edit'AddCon,
    -- Change category properties
    CopyM 'Edit'SetCategoryTitle,
    CopyM 'Edit'SetCategoryNotes,
    -- Change item properties
    CopyM 'Edit'SetItemName,
    CopyM 'Edit'SetItemLink,
    CopyM 'Edit'SetItemGroup,
    CopyM 'Edit'SetItemKind,
    CopyM 'Edit'SetItemDescription,
    CopyM 'Edit'SetItemNotes,
    CopyM 'Edit'SetItemEcosystem,
    -- Change trait properties
    CopyM 'Edit'SetTraitContent,
    -- Delete
    CopyM 'Edit'DeleteCategory,
    CopyM 'Edit'DeleteItem,
    CopyM 'Edit'DeleteTrait,
    -- Other
    CopyM 'Edit'MoveItem,
    CopyM 'Edit'MoveTrait
    ])

-- | Determine whether the edit doesn't actually change anything and so isn't
-- worth recording in the list of pending edits.
isVacuousEdit :: Edit -> Bool
isVacuousEdit Edit'SetCategoryTitle{..} =
  editCategoryTitle == editCategoryNewTitle
isVacuousEdit Edit'SetCategoryNotes{..} =
  editCategoryNotes == editCategoryNewNotes
isVacuousEdit Edit'SetItemName{..} =
  editItemName == editItemNewName
isVacuousEdit Edit'SetItemLink{..} =
  editItemLink == editItemNewLink
isVacuousEdit Edit'SetItemGroup{..} =
  editItemGroup == editItemNewGroup
isVacuousEdit Edit'SetItemKind{..} =
  editItemKind == editItemNewKind
isVacuousEdit Edit'SetItemDescription{..} =
  editItemDescription == editItemNewDescription
isVacuousEdit Edit'SetItemNotes{..} =
  editItemNotes == editItemNewNotes
isVacuousEdit Edit'SetItemEcosystem{..} =
  editItemEcosystem == editItemNewEcosystem
isVacuousEdit Edit'SetTraitContent{..} =
  editTraitContent == editTraitNewContent
isVacuousEdit _ = False

data EditDetails = EditDetails {
  editIP   :: Maybe IP,
  editDate :: UTCTime,
  editId   :: Int }
  deriving (Eq, Show)

deriveSafeCopySimple 2 'extension ''EditDetails

data EditDetails_v1 = EditDetails_v1 {
  editIP_v1   :: Maybe IP,
  editDate_v1 :: UTCTime,
  editId_v1   :: Int }

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 1 'base ''EditDetails_v1

instance Migrate EditDetails where
  type MigrateFrom EditDetails = EditDetails_v1
  migrate EditDetails_v1{..} = EditDetails {
    editIP = editIP_v1,
    editDate = editDate_v1,
    editId = editId_v1 }

-- TODO: add a function to create a checkpoint to the admin panel?

-- See Note [acid-state]

data GlobalState = GlobalState {
  _categories :: [Category],
  _categoriesDeleted :: [Category],
  -- | Pending edits, newest first
  _pendingEdits :: [(Edit, EditDetails)],
  -- | ID of next edit that will be made
  _editIdCounter :: Int }
  deriving (Show)

deriveSafeCopySimple 3 'extension ''GlobalState
makeLenses ''GlobalState

data GlobalState_v2 = GlobalState_v2 {
  _categories_v2 :: [Category],
  _categoriesDeleted_v2 :: [Category],
  _pendingEdits_v2 :: [(Edit, EditDetails)],
  _editIdCounter_v2 :: Int }

-- TODO: at the next migration change this to deriveSafeCopySimple!
deriveSafeCopy 2 'base ''GlobalState_v2

instance Migrate GlobalState where
  type MigrateFrom GlobalState = GlobalState_v2
  migrate GlobalState_v2{..} = GlobalState {
    _categories = _categories_v2,
    _categoriesDeleted = _categoriesDeleted_v2,
    _pendingEdits = _pendingEdits_v2,
    _editIdCounter = _editIdCounter_v2 }

addGroupIfDoesNotExist :: Text -> Map Text Hue -> Map Text Hue
addGroupIfDoesNotExist g gs
  | M.member g gs = gs
  | otherwise     = M.insert g firstNotTaken gs
  where
    firstNotTaken = head $ map Hue [1..] \\ M.elems gs

traitById :: Uid Trait -> Lens' Item Trait
traitById uid' = singular $
  (pros.each . filtered (hasUid uid')) `failing`
  (cons.each . filtered (hasUid uid')) `failing`
  error ("traitById: couldn't find trait with uid " ++
         T.unpack (uidToText uid'))

categoryById :: Uid Category -> Lens' GlobalState Category
categoryById catId = singular $
  categories.each . filtered (hasUid catId) `failing`
  error ("categoryById: couldn't find category with uid " ++
         T.unpack (uidToText catId))

itemById :: Uid Item -> Lens' GlobalState Item
itemById itemId = singular $
  categories.each . items.each . filtered (hasUid itemId) `failing`
  error ("itemById: couldn't find item with uid " ++
         T.unpack (uidToText itemId))

findCategoryByItem :: Uid Item -> GlobalState -> Category
findCategoryByItem itemId s =
  fromMaybe (error err) (find hasItem (s^.categories))
  where
    err = "findCategoryByItem: couldn't find category with item with uid " ++
          T.unpack (uidToText itemId)
    hasItem category = itemId `elem` (category^..items.each.uid)

hasUid :: HasUid a (Uid u) => Uid u -> a -> Bool
hasUid u x = x^.uid == u

-- get

getGlobalState :: Acid.Query GlobalState GlobalState
getGlobalState = view id

getCategories :: Acid.Query GlobalState [Category]
getCategories = view categories

getCategory :: Uid Category -> Acid.Query GlobalState Category
getCategory uid' = view (categoryById uid')

getCategoryMaybe :: Uid Category -> Acid.Query GlobalState (Maybe Category)
getCategoryMaybe uid' = preview (categoryById uid')

getCategoryByItem :: Uid Item -> Acid.Query GlobalState Category
getCategoryByItem uid' = findCategoryByItem uid' <$> ask

getItem :: Uid Item -> Acid.Query GlobalState Item
getItem uid' = view (itemById uid')

-- TODO: this doesn't need the item id, but then we have to be a bit cleverer
-- and store a (TraitId -> ItemId) map in global state (and update it
-- accordingly whenever anything happens, so perhaps let's not do it!)
getTrait :: Uid Item -> Uid Trait -> Acid.Query GlobalState Trait
getTrait itemId traitId = view (itemById itemId . traitById traitId)

-- | A useful lens operator that modifies something and returns the old value.
(<<.=) :: MonadState s m => LensLike ((,) a) s s a b -> b -> m a
(<<.=) l b = state (l (,b))
{-# INLINE (<<.=) #-}
infix 4 <<.=

-- add

addCategory
  :: Uid Category    -- ^ New category's id
  -> Text            -- ^ Title
  -> UTCTime         -- ^ Creation time
  -> Acid.Update GlobalState (Edit, Category)
addCategory catId title' created' = do
  let newCategory = Category {
        _categoryUid = catId,
        _categoryTitle = title',
        _categoryCreated = created',
        _categoryNotes = "",
        _categoryGroups = mempty,
        _categoryItems = [],
        _categoryItemsDeleted = [] }
  categories %= (newCategory :)
  let edit = Edit'AddCategory catId title'
  return (edit, newCategory)

addItem
  :: Uid Category    -- ^ Category id
  -> Uid Item        -- ^ New item's id
  -> Text            -- ^ Name
  -> UTCTime         -- ^ Creation time
  -> ItemKind        -- ^ Kind
  -> Acid.Update GlobalState (Edit, Item)
addItem catId itemId name' created' kind' = do
  let newItem = Item {
        _itemUid         = itemId,
        _itemName        = name',
        _itemCreated     = created',
        _itemGroup_      = Nothing,
        _itemDescription = "",
        _itemPros        = [],
        _itemProsDeleted = [],
        _itemCons        = [],
        _itemConsDeleted = [],
        _itemEcosystem   = "",
        _itemNotes       = "",
        _itemLink        = Nothing,
        _itemKind        = kind' }
  categoryById catId . items %= (++ [newItem])
  let edit = Edit'AddItem catId itemId name'
  return (edit, newItem)

addPro
  :: Uid Item       -- ^ Item id
  -> Uid Trait      -- ^ New trait's id
  -> Text
  -> Acid.Update GlobalState (Edit, Trait)
addPro itemId traitId text' = do
  let newTrait = Trait traitId (renderMarkdownInline text')
  itemById itemId . pros %= (++ [newTrait])
  let edit = Edit'AddPro itemId traitId text'
  return (edit, newTrait)

addCon
  :: Uid Item       -- ^ Item id
  -> Uid Trait      -- ^ New trait's id
  -> Text
  -> Acid.Update GlobalState (Edit, Trait)
addCon itemId traitId text' = do
  let newTrait = Trait traitId (renderMarkdownInline text')
  itemById itemId . cons %= (++ [newTrait])
  let edit = Edit'AddCon itemId traitId text'
  return (edit, newTrait)

-- set

-- Almost all of these return an 'Edit' that corresponds to the edit that has
-- been performed.

-- | Can be useful sometimes (e.g. if you want to regenerate all uids), but
-- generally shouldn't be used.
setGlobalState :: GlobalState -> Acid.Update GlobalState ()
setGlobalState = (id .=)

setCategoryTitle :: Uid Category -> Text -> Acid.Update GlobalState (Edit, Category)
setCategoryTitle catId title' = do
  oldTitle <- categoryById catId . title <<.= title'
  let edit = Edit'SetCategoryTitle catId oldTitle title'
  (edit,) <$> use (categoryById catId)

setCategoryNotes :: Uid Category -> Text -> Acid.Update GlobalState (Edit, Category)
setCategoryNotes catId notes' = do
  oldNotes <- categoryById catId . notes <<.= renderMarkdownBlock notes'
  let edit = Edit'SetCategoryNotes catId (markdownBlockText oldNotes) notes'
  (edit,) <$> use (categoryById catId)

setItemName :: Uid Item -> Text -> Acid.Update GlobalState (Edit, Item)
setItemName itemId name' = do
  oldName <- itemById itemId . name <<.= name'
  let edit = Edit'SetItemName itemId oldName name'
  (edit,) <$> use (itemById itemId)

setItemLink :: Uid Item -> Maybe Url -> Acid.Update GlobalState (Edit, Item)
setItemLink itemId link' = do
  oldLink <- itemById itemId . link <<.= link'
  let edit = Edit'SetItemLink itemId oldLink link'
  (edit,) <$> use (itemById itemId)

-- Also updates the list of groups in the category
setItemGroup :: Uid Item -> Maybe Text -> Acid.Update GlobalState (Edit, Item)
setItemGroup itemId newGroup = do
  catId <- view uid . findCategoryByItem itemId <$> get
  let categoryLens :: Lens' GlobalState Category
      categoryLens = categoryById catId
  let itemLens :: Lens' GlobalState Item
      itemLens = itemById itemId
  -- If the group is new, add it to the list of groups in the category (which
  -- causes a new hue to be generated, too)
  case newGroup of
    Nothing -> return ()
    Just x  -> categoryLens.groups %= addGroupIfDoesNotExist x
  -- Update list of groups if the group is going to be empty after the item
  -- is moved to a different group. Note that this is done after adding a new
  -- group because we also want the color to change. So, if the item was the
  -- only item in its group, the sequence of actions is as follows:
  -- 
  --   * new group is added (and hence a new color is assigned)
  --   * old group is deleted (and now the old color is unused)
  oldGroup <- use (itemLens.group_)
  case oldGroup of
    Nothing -> return ()
    Just g  -> when (oldGroup /= newGroup) $ do
      allItems <- use (categoryLens.items)
      let inOurGroup item = item^.group_ == Just g
      when (length (filter inOurGroup allItems) == 1) $
        categoryLens.groups %= M.delete g
  -- Now we can actually change the group
  itemLens.group_ .= newGroup
  let edit = Edit'SetItemGroup itemId oldGroup newGroup
  (edit,) <$> use itemLens

setItemKind :: Uid Item -> ItemKind -> Acid.Update GlobalState (Edit, Item)
setItemKind itemId kind' = do
  oldKind <- itemById itemId . kind <<.= kind'
  let edit = Edit'SetItemKind itemId oldKind kind'
  (edit,) <$> use (itemById itemId)

setItemDescription :: Uid Item -> Text -> Acid.Update GlobalState (Edit, Item)
setItemDescription itemId description' = do
  oldDescr <- itemById itemId . description <<.=
                renderMarkdownBlock description'
  let edit = Edit'SetItemDescription itemId
               (markdownBlockText oldDescr) description'
  (edit,) <$> use (itemById itemId)

setItemNotes :: Uid Item -> Text -> Acid.Update GlobalState (Edit, Item)
setItemNotes itemId notes' = do
  oldNotes <- itemById itemId . notes <<.= renderMarkdownBlock notes'
  let edit = Edit'SetItemNotes itemId (markdownBlockText oldNotes) notes'
  (edit,) <$> use (itemById itemId)

setItemEcosystem :: Uid Item -> Text -> Acid.Update GlobalState (Edit, Item)
setItemEcosystem itemId ecosystem' = do
  oldEcosystem <- itemById itemId . ecosystem <<.=
                    renderMarkdownBlock ecosystem'
  let edit = Edit'SetItemEcosystem itemId
               (markdownBlockText oldEcosystem) ecosystem'
  (edit,) <$> use (itemById itemId)

setTraitContent :: Uid Item -> Uid Trait -> Text -> Acid.Update GlobalState (Edit, Trait)
setTraitContent itemId traitId content' = do
  oldContent <- itemById itemId . traitById traitId . content <<.=
                  renderMarkdownInline content'
  let edit = Edit'SetTraitContent itemId traitId
               (markdownInlineText oldContent) content'
  (edit,) <$> use (itemById itemId . traitById traitId)

-- delete

deleteCategory :: Uid Category -> Acid.Update GlobalState (Either String Edit)
deleteCategory catId = do
  mbCategory <- preuse (categoryById catId)
  case mbCategory of
    Nothing       -> return (Left "category not found")
    Just category -> do
      mbCategoryPos <- findIndex (hasUid catId) <$> use categories
      case mbCategoryPos of
        Nothing          -> return (Left "category not found")
        Just categoryPos -> do
          categories %= deleteAt categoryPos
          categoriesDeleted %= (category:)
          return (Right (Edit'DeleteCategory catId categoryPos))

deleteItem :: Uid Item -> Acid.Update GlobalState (Either String Edit)
deleteItem itemId = do
  catId <- view uid . findCategoryByItem itemId <$> get
  let categoryLens :: Lens' GlobalState Category
      categoryLens = categoryById catId
  let itemLens :: Lens' GlobalState Item
      itemLens = itemById itemId
  mbItem <- preuse itemLens
  case mbItem of
    Nothing   -> return (Left "item not found")
    Just item -> do
      allItems <- use (categoryLens.items)
      -- If the item was the only item in its group, delete the group (and
      -- make the hue available for new items)
      case item^.group_ of
        Nothing       -> return ()
        Just oldGroup -> do
          let itemsInOurGroup = [item' | item' <- allItems,
                                         item'^.group_ == Just oldGroup]
          when (length itemsInOurGroup == 1) $
            categoryLens.groups %= M.delete oldGroup
      -- And now delete the item (i.e. move it to “deleted”)
      case findIndex (hasUid itemId) allItems of
        Nothing      -> return (Left "item not found")
        Just itemPos -> do
          categoryLens.items        %= deleteAt itemPos
          categoryLens.itemsDeleted %= (item:)
          return (Right (Edit'DeleteItem itemId itemPos))

deleteTrait :: Uid Item -> Uid Trait -> Acid.Update GlobalState (Either String Edit)
deleteTrait itemId traitId = do
  let itemLens :: Lens' GlobalState Item
      itemLens = itemById itemId
  mbItem <- preuse itemLens
  case mbItem of
    Nothing   -> return (Left "item not found")
    Just item -> do
      -- Determine whether the trait is a pro or a con, and proceed accordingly
      case (find (hasUid traitId) (item^.pros),
            find (hasUid traitId) (item^.cons)) of
        -- It's in neither group, which means it was deleted. Do nothing.
        (Nothing, Nothing) -> return (Left "trait not found")
        -- It's a pro
        (Just trait, _) -> do
          mbTraitPos <- findIndex (hasUid traitId) <$> use (itemLens.pros)
          case mbTraitPos of
            Nothing       -> return (Left "trait not found")
            Just traitPos -> do
              itemLens.pros        %= deleteAt traitPos
              itemLens.prosDeleted %= (trait:)
              return (Right (Edit'DeleteTrait itemId traitId traitPos))
        -- It's a con
        (_, Just trait) -> do
          mbTraitPos <- findIndex (hasUid traitId) <$> use (itemLens.cons)
          case mbTraitPos of
            Nothing       -> return (Left "trait not found")
            Just traitPos -> do
              itemLens.cons        %= deleteAt traitPos
              itemLens.consDeleted %= (trait:)
              return (Right (Edit'DeleteTrait itemId traitId traitPos))

-- other methods

moveItem
  :: Uid Item
  -> Bool       -- ^ 'True' means up, 'False' means down
  -> Acid.Update GlobalState Edit
moveItem itemId up = do
  let move = if up then moveUp else moveDown
  catId <- view uid . findCategoryByItem itemId <$> get
  categoryById catId . items %= move (hasUid itemId)
  return (Edit'MoveItem itemId up)

moveTrait
  :: Uid Item
  -> Uid Trait
  -> Bool        -- ^ 'True' means up, 'False' means down
  -> Acid.Update GlobalState Edit
moveTrait itemId traitId up = do
  let move = if up then moveUp else moveDown
  -- The trait is only going to be present in one of the lists so let's do it
  -- in each list because we're too lazy to figure out whether it's a pro or
  -- a con
  itemById itemId . pros %= move (hasUid traitId)
  itemById itemId . cons %= move (hasUid traitId)
  return (Edit'MoveTrait itemId traitId up)

restoreCategory :: Uid Category -> Int -> Acid.Update GlobalState (Either String ())
restoreCategory catId pos = do
  deleted <- use categoriesDeleted
  case find (hasUid catId) deleted of
    Nothing -> return (Left "category not found in deleted categories")
    Just category -> do
      categoriesDeleted %= deleteFirst (hasUid catId)
      categories        %= insertAt pos category
      return (Right ())

restoreItem :: Uid Item -> Int -> Acid.Update GlobalState (Either String ())
restoreItem itemId pos = do
  let ourCategory = any (hasUid itemId) . view itemsDeleted
  allCategories <- use (categories <> categoriesDeleted)
  case find ourCategory allCategories of
    Nothing -> return (Left "item not found in deleted items")
    Just category -> do
      let item = fromJust (find (hasUid itemId) (category^.itemsDeleted))
      let category' = category
            & itemsDeleted %~ deleteFirst (hasUid itemId)
            & items        %~ insertAt pos item
      categories        . each . filtered ourCategory .= category'
      categoriesDeleted . each . filtered ourCategory .= category'
      return (Right ())

restoreTrait :: Uid Item -> Uid Trait -> Int -> Acid.Update GlobalState (Either String ())
restoreTrait itemId traitId pos = do
  let getItems = view (items <> itemsDeleted)
      ourCategory = any (hasUid itemId) . getItems
  allCategories <- use (categories <> categoriesDeleted)
  case find ourCategory allCategories of
    Nothing -> return (Left "item -that the trait belongs to- not found")
    Just category -> do
      let item = fromJust (find (hasUid itemId) (getItems category))
      case (find (hasUid traitId) (item^.prosDeleted),
            find (hasUid traitId) (item^.consDeleted)) of
        (Nothing, Nothing) -> return (Left "trait not found in deleted traits")
        (Just trait, _) -> do
          let item' = item
                & prosDeleted %~ deleteFirst (hasUid traitId)
                & pros        %~ insertAt pos trait
          let category' = category
                & items        . each . filtered (hasUid itemId) .~ item'
                & itemsDeleted . each . filtered (hasUid itemId) .~ item'
          categories        . each . filtered ourCategory .= category'
          categoriesDeleted . each . filtered ourCategory .= category'
          return (Right ())
        (_, Just trait) -> do
          let item' = item
                & consDeleted %~ deleteFirst (hasUid traitId)
                & cons        %~ insertAt pos trait
          let category' = category
                & items        . each . filtered (hasUid itemId) .~ item'
                & itemsDeleted . each . filtered (hasUid itemId) .~ item'
          categories        . each . filtered ourCategory .= category'
          categoriesDeleted . each . filtered ourCategory .= category'
          return (Right ())

-- TODO: maybe have a single list of traits with pro/con being signified by
-- something like TraitType? or maybe TraitType could even be a part of the
-- trait itself?

getEdit :: Int -> Acid.Query GlobalState (Edit, EditDetails)
getEdit n = do
  edits <- view pendingEdits
  case find ((== n) . editId . snd) edits of
    Nothing   -> error ("no edit with id " ++ show n)
    Just edit -> return edit

-- | Returns edits in order from latest to earliest.
getEdits
  :: Int            -- ^ Id of latest edit
  -> Int            -- ^ Id of earliest edit
  -> Acid.Query GlobalState [(Edit, EditDetails)]
getEdits m n =
  filter (\(_, d) -> n <= editId d && editId d <= m) <$> view pendingEdits

-- | The edit won't be registered if it's vacuous (see 'isVacuousEdit').
registerEdit
  :: Edit
  -> Maybe IP
  -> UTCTime
  -> Acid.Update GlobalState ()
registerEdit ed ip date = do
  id' <- use editIdCounter
  let details = EditDetails {
        editIP   = ip,
        editDate = date,
        editId   = id' }
  pendingEdits %= ((ed, details):)
  editIdCounter += 1

removePendingEdit :: Int -> Acid.Update GlobalState (Edit, EditDetails)
removePendingEdit n = do
  edits <- use pendingEdits
  case find ((== n) . editId . snd) edits of
    Nothing   -> error ("no edit with id " ++ show n)
    Just edit -> do
      pendingEdits %= deleteFirst ((== n) . editId . snd)
      return edit

removePendingEdits
  :: Int            -- ^ Id of latest edit
  -> Int            -- ^ Id of earliest edit
  -> Acid.Update GlobalState ()
removePendingEdits m n = do
  pendingEdits %= filter (\(_, d) -> editId d < n || m < editId d)

makeAcidic ''GlobalState [
  -- queries
  'getGlobalState,
  'getCategories,
  'getCategory, 'getCategoryMaybe,
  'getCategoryByItem,
  'getItem,
  'getTrait,
  -- add
  'addCategory,
  'addItem,
  'addPro, 'addCon,
  -- set
  'setGlobalState,
  'setCategoryTitle, 'setCategoryNotes,
  'setItemName, 'setItemLink, 'setItemGroup, 'setItemKind,
    'setItemDescription, 'setItemNotes, 'setItemEcosystem,
  'setTraitContent,
  -- delete
  'deleteCategory,
  'deleteItem,
  'deleteTrait,
  -- edits
  'getEdit, 'getEdits,
  'registerEdit,
  'removePendingEdit, 'removePendingEdits,
  -- other
  'moveItem, 'moveTrait,
  'restoreCategory, 'restoreItem, 'restoreTrait
  ]
